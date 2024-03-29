

proc load_generators {} {
	global script_path
	set scripts [ glob "$script_path/generators/*.tcl" ]
	foreach script $scripts {
	  source $script
	}		
}

namespace eval gen {
array set generators {}


proc add_generator { language generator } {
	variable generators
	if { [ info exists generator($language) ] } {
		error "Generator for language $language already registered."
	}
	set generators($language) $generator
}

proc p.shout { message } {
	mw::set_status $message
	tk_messageBox -parent . -message $message -type ok
}

proc get_start_icon { gdb diagram_id } {
	return [ $gdb onecolumn {
		select start_icon
		from branches
		where diagram_id = :diagram_id
			and ordinal = 1 } ]
}


proc generate { } {
	variable generators

	array set properties [ mwc::get_file_properties ]
	if { ![ info exists properties(language) ] } {
		mw::set_status "Language not configured, showing file properties."
		fprops::show_dialog gen::generate
		return
	}
	
	set language $properties(language)
	mw::set_status "Generating code for '$language' language..."
	update

	if { ![ info exists generators($language) ] } {
		p.shout "No generator for language '$language'."
		return
	}

	unpack $generators($language) generator extension

	set verification_ok [ mw::verify_all ]
	if { !$verification_ok } { 
		mw::set_status "Errors found, generation stopped."
		return
	}

	if { [ catch { p.do_generate $generator $language } result ] } {
		p.shout "Error occurred: $result"
		puts "Error info $result\nFull info: $::errorInfo"
	}
}


proc generate_no_gui { dst_filename } {
	variable generators
	
	set db [ mwc::get_db ]

	array set properties [ mwc::get_file_properties ]
	if { ![ info exists properties(language) ] } {
		puts "Language not configured. Choose a language."
		puts "In main menu: File / File properties..."
		exit 1
	}
	
	set language $properties(language)

	if { ![ info exists generators($language) ] } {
		puts "No generator for language '$language'."
		exit 1
	}

	unpack $generators($language) generator extension
	
	graph::verify_all $db


	set error_list [ graph::get_error_list ]
	
	if { [ llength $error_list ] != 0 } {
		foreach error_line $error_list {
			puts $error_line
		}
		exit 1
	}

	p.do_generate $generator $language $dst_filename
}


proc p.do_generate { generator language { filename "" } } {
	global g_filename
	set db [ mwc::get_db ]
	set gdb "gdb"
	if { $filename == "" } {
		set filename $g_filename
	}
	$generator $db $gdb $filename
	if { [ graph::errors_occured ] } {
		mw::set_status "Errors occured."
		mw::get_errors
	} else {
		mw::set_status "Code generation for '$language' language complete."
	}
}

proc p.try_extract_header { line } {
	set trimmed [ string trim $line ]
	set length [ string length $trimmed ]
	if { $length < 7 } { return "" }
	set begin [ string range $trimmed 0 2 ]
	set end [ string range $trimmed end-2 end ]
	if { $begin != "===" || $end != "===" } { return "" }
	set middle [ string range $trimmed 3 end-3 ]
	set header [ string trim $middle ]
	return $header
}

proc fix_graph { gdb callbacks append_semicolon } {
	$gdb eval {
		update vertices
		set type = 'action'
		where type = 'insertion'
	}

	set starts [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'loopstart' } ]

	foreach start $starts {
		p.rewire_loop $gdb $start $callbacks $append_semicolon
	}

	set selects [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'select' } ]
	foreach select $selects {
		p.rewire_select $gdb $select $callbacks
	}
	
	set ifs [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'if' } ]
	
	foreach if_id $ifs {
		p.rewire_if $gdb $if_id
	}

	p.clean_tech_vertices $gdb

	p.remove_branch_icons $gdb


	p.glue_actions $gdb $callbacks
	
	while { [ p.short_circuit $gdb $callbacks ] } { }
}

proc p.v_type { gdb vertex_id } {
	return [ $gdb onecolumn {
		select type
		from vertices
		where vertex_id = :vertex_id
	} ]
}

proc p.set_vertex_text { gdb vertex_id text } {
	$gdb eval {
		update vertices
		set text = :text
		where vertex_id = :vertex_id
	}
}

proc p.has_one_entry { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :vertex_id } ]
	
	return [ expr { $count == 1 } ]
}

proc p.short_circuit { gdb callbacks } {
	set and [ get_callback $callbacks and ]
	set or [ get_callback $callbacks or ]
	set not [ get_callback $callbacks not ]
	
	set ifs [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'if' } ]

	set result 0

	foreach if_id $ifs {
		set text [ p.vertex_text $gdb $if_id ]
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		set one_type [ p.v_type $gdb $one ]
		
		if { $one != $if_id && $one_type == "if" && [ p.has_one_entry $gdb $one ] } {
			set ctext [ p.vertex_text $gdb $one ]
			set cone [ p.link_dst $gdb $one 1 ]
			set ctwo [ p.link_dst $gdb $one 2 ]

			if { $ctwo == $two } {
				set result 1
				# OR
				p.set_link_dst $gdb $if_id 1 $cone
				p.unlink $gdb $one
				$gdb eval { delete from vertices where vertex_id = :one }
				set ntext [ $or $text $ctext ]
				p.set_vertex_text $gdb $if_id $ntext
				
			} elseif { $cone == $two } {
				set result 1			
				# OR NOT
				p.set_link_dst $gdb $if_id 1 $ctwo
				p.unlink $gdb $one
				$gdb eval { delete from vertices where vertex_id = :one }
				set ntext [ $or $text [ $not $ctext ] ]
				p.set_vertex_text $gdb $if_id $ntext			
			}
		}

		set text [ p.vertex_text $gdb $if_id ]
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		set two_type [ p.v_type $gdb $two ]
		
		if { $two != $if_id && $two_type == "if" && [ p.has_one_entry $gdb $two ] } {
			set ctext [ p.vertex_text $gdb $two ]
			set cone [ p.link_dst $gdb $two 1 ]
			set ctwo [ p.link_dst $gdb $two 2 ]

			if { $cone == $one } {
				set result 1
				# AND
				p.set_link_dst $gdb $if_id 2 $ctwo
				p.unlink $gdb $two
				$gdb eval { delete from vertices where vertex_id = :two }
				set ntext [ $and $text $ctext ]
				p.set_vertex_text $gdb $if_id $ntext
				
			} elseif { $ctwo == $one } {
				set result 1			
				# AND NOT
				p.set_link_dst $gdb $if_id 2 $cone
				p.unlink $gdb $two
				$gdb eval { delete from vertices where vertex_id = :two }
				set ntext [ $and $text [ $not $ctext ] ]
				p.set_vertex_text $gdb $if_id $ntext				
			}
		}

		
		if { $result } { break }
	}
	
	return $result
}

proc p.rewire_if { gdb if_id } {
	set b [ $gdb onecolumn {
		select b
		from vertices
		where vertex_id = :if_id } ]
	if { $b } {
		set one [ p.link_dst $gdb $if_id 1 ]
		set two [ p.link_dst $gdb $if_id 2 ]
		$gdb eval {
			update links set dst = :two
			where src = :if_id and ordinal = 1;
			
			update links set dst = :one
			where src = :if_id and ordinal = 2;			
			
			update vertices set b = 0
			where vertex_id = :if_id;
		}
	}
}

proc p.clean_tech_vertices { gdb } {
	set vertices [ $gdb eval {
		select vertex_id
		from vertices
		where type is null
	} ]
	foreach vertex_id $vertices {
		$gdb eval {
			delete from links
			where src = :vertex_id;
			delete from vertices
			where vertex_id = :vertex_id
		}
	}
}

proc p.vertex_exists { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*) from vertices
		where vertex_id = :vertex_id } ]
	return [ expr { $count > 0 } ]
}

proc p.get_single_next { gdb vertex_id } {
	set dsts [ $gdb eval {
		select dst
		from links
		where src = :vertex_id } ]
	if { [ llength $dsts ] != 1 } { return "" }
	set dst [ lindex $dsts 0 ]
	
	set incoming [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :dst } ]
	if { $incoming != 1 } { return "" }

	return $dst
}

proc p.same_type { gdb vertex1 vertex2 } {
	set type1 [ p.vertex_type $gdb $vertex1 ]
	set type2 [ p.vertex_type $gdb $vertex2 ]
	if { $type1 == "insertion" } { set type1 action }
	if { $type2 == "insertion" } { set type2 action }	
	return [ expr { $type1 == $type2 } ]
}

proc p.merge_vertices { gdb vertex_id next commentator line_end } {
	set this_text [ p.vertex_text $gdb $vertex_id ]
	set that_text [ p.vertex_text $gdb $next ]
	set that_item [ p.vertex_item $gdb $next ]
	set marker [ $commentator "item $that_item" ]
	set new_text "$this_text$line_end\n$marker\n$that_text"
	$gdb eval {
		update vertices
		set text = :new_text
		where vertex_id = :vertex_id
	}

	p.delete_vertex $gdb $next
}

proc p.glue_actions { gdb callbacks } {
	set commentator [ get_callback $callbacks comment ]
	set line_end [ get_optional_callback $callbacks line_end ]
	set vertices [ $gdb eval {
		select vertex_id
		from vertices
		where type != 'beginend'
	} ]
	foreach vertex_id $vertices {
		if { ![ p.vertex_exists $gdb $vertex_id ] } { continue }
		set next [ p.get_single_next $gdb $vertex_id ]
		while { $next != "" && [ p.same_type $gdb $vertex_id $next ] } {
			p.merge_vertices $gdb $vertex_id $next $commentator $line_end
			set next [ p.get_single_next $gdb $vertex_id ]
		}		
	}
}

proc p.remove_branches_from_dia { gdb diagram_id } {
	
	set vertices [ $gdb eval {
		select vertex_id
		from vertices
		where diagram_id = :diagram_id } ]

	foreach vertex_id $vertices {
		set type [ p.vertex_type $gdb $vertex_id ]

		if { $type == "branch" || $type == "address" } {
			p.delete_vertex $gdb $vertex_id
		}
	}
}

proc p.remove_branch_icons { gdb } {
	$gdb eval { select diagram_id from diagrams } {
		unpack [ $gdb eval {
			select start_icon, header_icon
			from branches
			where diagram_id = :diagram_id
				and ordinal = 1 
		} ] start_icon header_icon
		if { $header_icon != "" } {
			p.link $gdb $start_icon 1 $header_icon
		}
		p.remove_branches_from_dia $gdb $diagram_id
	}
}


proc p.extract_foreach { text } {
	if { ![ string match "foreach *" $text ] } { return "" }
	set foreach_length [ string length "foreach " ]
	set body [ string range $text $foreach_length end ]
	set parts [ split $body ";" ]
	if { [ llength $parts ] != 2 } { return "" }
	set result {}
	foreach part $parts {
		set trimmed [ string trim $part ]
		if { $trimmed == "" } { return "" }
		lappend result $trimmed
	}
	return $result	
}

proc p.extract_for { text } {
	set parts [ split $text ";" ]
	if { [ llength $parts ] != 3 } { return "" }
	set result {}
	foreach part $parts {
		set trimmed [ string trim $part ]
		if { $trimmed == "" } { return "" }
		lappend result $trimmed
	}
	return $result
}

proc p.vertex_text { gdb vertex_id } {
	return [ $gdb onecolumn { select text from vertices
		where vertex_id = :vertex_id } ]
}

proc p.link_dst { gdb src ordinal } {
	return [ $gdb onecolumn {
		select dst
		from links	
		where src = :src and ordinal = :ordinal } ]
}

proc p.link_const { gdb src ordinal } {
	return [ $gdb onecolumn {
		select constant
		from links	
		where src = :src and ordinal = :ordinal } ]
}


proc p.set_link_constant { gdb src ordinal constant } {
	$gdb eval {
		update links
		set constant = :constant
		where src = :src and ordinal = :ordinal
	}
}

proc p.set_link_dst { gdb src ordinal dst } {
	$gdb eval {
		update links
		set dst = :dst
		where src = :src and ordinal = :ordinal
	}
}


proc p.delete_vertex { gdb vertex_id } {
	set oords [ $gdb eval {
		select ordinal
		from links
		where src = :vertex_id } ]
	if { [ llength $oords ] > 1 } {
		error "Should be at most one link for vertex $vertex_id"
	}
	
	if { [ llength $oords ] == 1 } {
		set oord [ lindex $oords 0 ]
		set next_vertex [ p.link_dst $gdb $vertex_id $oord ]
		$gdb eval {
			update links
			set dst = :next_vertex
			where dst = :vertex_id;
		}
	}
	
	$gdb eval {
		delete from links
		where src = :vertex_id;		
	
		delete from vertices
		where vertex_id = :vertex_id;
	}
}

proc p.rewire_select { gdb select callbacks } {
	set ordinals [ $gdb eval {
		select ordinal
		from links
		where src = :select } ]

	foreach ordinal $ordinals {
		set dst [ p.link_dst $gdb $select $ordinal ]
		set constant [ p.vertex_text $gdb $dst ]
		p.set_link_constant $gdb $select $ordinal $constant
		p.delete_vertex $gdb $dst
	}
	
	p.replace_select_ifs $gdb $select $ordinals $callbacks
}

proc p.switch_var { item_id } {
	return "_sw${item_id}_"
}

proc p.save_declare { gdb diagram_id type name value callbacks } {
	set declarer [ get_callback $callbacks declare ]
	set line [ $declarer $type $name $value ]
	p.save_declare_kernel $gdb $diagram_id $line
}

proc p.save_declare_kernel { gdb diagram_id lines } {
	set lines_list [ split $lines "\n" ]
	foreach line $lines_list {
		$gdb eval {
			insert into declares (diagram_id, line)
			values (:diagram_id, :line)
		}
	}
}

proc p.get_declares { gdb diagram_id } {
	return [ $gdb eval {
		select line
		from declares 
		where diagram_id = :diagram_id } ]
}

proc p.replace_select_ifs { gdb select ordinals callbacks } {
	set assign [ get_callback $callbacks assign ]
	set bad_case [ get_callback $callbacks bad_case ]
	
	set select_item [ p.vertex_item $gdb $select ]
	set select_text [ p.vertex_text $gdb $select ]	
	set diagram_id [ p.vertex_diagram $gdb $select ]
	
	set select_item [ expr { $select_item * 10000 } ]
	set compare [ get_callback $callbacks compare ]
	
	if { ![ is_variable $select_text ] } {
		
		set var_name [ p.switch_var $select_item ]
		set init_text [ $assign $var_name $select_text ]
		set init_id [ p.insert_vertex $gdb $diagram_id $select_item action $init_text 0 ]
		p.relink $gdb $select $init_id
		set parent $init_id
		p.save_declare $gdb $diagram_id "int" $var_name "0" $callbacks
	} else {
		
		set var_name [ string map {"\$" "" } $select_text ]
		set parent ""	
	}

	set count [ llength $ordinals ]
	set last [ expr { $count - 1 } ]
	for { set i 0 } { $i < $count } { incr i } {
	
		incr select_item
		set ordinal [ lindex $ordinals $i ]
		set const [ p.link_const $gdb $select $ordinal ]
		set dst [ p.link_dst $gdb $select $ordinal ]
		
		if { $i == $last && $const == "" } {
			p.link $gdb $parent 1 $dst
		} else {
			set comp_text [ $compare $var_name $const ]
			set if_id [ p.insert_vertex $gdb $diagram_id $select_item if $comp_text 0 ]

			
			if { $i == $last } {
				set fail_text [ $bad_case $var_name ]
				incr select_item
				set fail_id [ p.insert_vertex $gdb $diagram_id $select_item action $fail_text 0 ]
				
				p.link $gdb $if_id 2 $dst
				p.link $gdb $if_id 1 $fail_id
				p.link $gdb $fail_id 1 $dst
			} else {
				p.link $gdb $if_id 2 $dst
			}
			
			if { $parent == "" } {
				p.relink $gdb $select $if_id
			} else {
				p.link $gdb $parent 1 $if_id
			}			
			
			set parent $if_id
		}		
	}
	

	p.unlink $gdb $select
	p.delete_vertex $gdb $select
}

proc p.unlink { gdb src } {
	$gdb eval {
		delete from links
		where src = :src }
}

proc p.vertex_type { gdb vertex_id } {
	return [ $gdb onecolumn {
		select type
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.vertex_item { gdb vertex_id } {
	return [ $gdb onecolumn {
		select item_id
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.vertex_diagram { gdb vertex_id } {
	return [ $gdb onecolumn {
		select diagram_id
		from vertices
		where vertex_id = :vertex_id } ]
}

proc p.get_next { gdb src ordinal } {
	return [ $gdb onecolumn {
		select dst
		from links
		where src = :src and ordinal = :ordinal } ]
}

proc p.next_on_skewer { gdb vertex_id } {
	return [ p.get_next $gdb $vertex_id 1 ]
}

proc p.find_end { gdb start } {
	set current [ p.get_next $gdb $start 2 ]
	while { 1 } {
		if { $current == "" } { break }
		set type [ p.vertex_type $gdb $current ]
		if { $type == "loopend" } {
			return $current
		}
		set current [ p.next_on_skewer $gdb $current ]
	}
	error "End not found for $start"
}

proc has_branches { gdb diagram_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from branches where diagram_id = :diagram_id } ]
	return [ expr { $count > 0 } ]
}


proc p.rewire_loop { gdb start callbacks append_semicolon } {
	set end [ p.find_end $gdb $start ]
	set text [ p.vertex_text $gdb $start ]
	set item_id [ p.vertex_item $gdb $start ]

	set type ""
	set parts ""
	if { [ string match "foreach *" $text ] && $callbacks != "" } {
		set parts [ p.extract_foreach $text ]
		set type "foreach"
	} else {
		set parts [ p.extract_for $text ]
		set type "for"
	}

	set diagram_id [ p.vertex_diagram $gdb $start ]
	
	if { $parts == "" } {
		set diagram_id [ p.vertex_diagram $gdb $start ]
		set item_id [ p.vertex_item $gdb $start ]
		graph::p.error $diagram_id [ list $item_id ] "Error in loop statement."
		error "Error in loop item $item_id"
	}

	if { $type == "for" } {
		p.rewire_for $gdb $start $end $parts $append_semicolon
	} elseif { $type == "foreach" } {
		p.rewire_foreach $gdb $diagram_id $start $end $parts $callbacks
	}
}

proc p.insert_vertex { gdb diagram_id item_id type text b } {
	set vertex_id [ mod::next_key $gdb vertices vertex_id ]
	$gdb eval {
		insert into vertices (vertex_id, diagram_id, item_id, type, text, b)
			values (:vertex_id, :diagram_id, :item_id, :type, :text, :b)
	}
	return $vertex_id
}

proc p.relink { gdb old_dst new_dst } {
	$gdb eval {
		update links
		set dst = :new_dst
		where dst = :old_dst
	}
}

proc p.link { gdb src ordinal dst } {
	$gdb eval {
		insert into links (src, ordinal, dst)
			values (:src, :ordinal, :dst)
	}
}

proc append_digits { number digits } {
	append number $digits
	return $number
}

proc p.rewire_foreach { gdb diagram_id start end parts callbacks } {

	set cinit [ get_callback $callbacks for_init ]
	set ccheck [ get_callback $callbacks for_check ]
	set ccurrent [ get_callback $callbacks for_current ]
	set cincr [ get_callback $callbacks for_incr ]
	set declare [ get_callback $callbacks for_declare ]
	
	unpack $parts first second

	set diagram_id [ p.vertex_diagram $gdb $start ]
	set item_id [ p.vertex_item $gdb $start ]

	set tinit [ $cinit $item_id $first $second ]
	set tcheck [ $ccheck $item_id $first $second ]
	set tcurrent [ $ccurrent $item_id $first $second ]
	set tincr [ $cincr $item_id $first $second ]
	set for_declare [ $declare $item_id $first $second ]
	
	p.save_declare_kernel $gdb $diagram_id $for_declare

	# check must always be present
	set check_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0002 ] "if" $tcheck 0 ]

	if { $tinit == "" } {
		p.relink $gdb $start $check_id
	} else {
		set init_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0001 ] "action" $tinit 0 ]
		p.relink $gdb $start $init_id
		p.link $gdb $init_id 1 $check_id
	}

	if { $tincr == "" } {
		p.relink $gdb $end $check_id
	} else {
		set advance_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0003 ] "action" $tincr 0 ]
		p.relink $gdb $end $advance_id
		p.link $gdb $advance_id 1 $check_id
	}

	set first_loop [ p.get_next $gdb $start 2 ]
	set after_loop [ p.get_next $gdb $start 1 ]
	p.link $gdb $check_id 1 $after_loop

	if { $tcurrent == "" } {
		p.link $gdb $check_id 2 $first_loop
	} else {
		set current_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0004 ] "action" $tcurrent 0 ]
		p.link $gdb $check_id 2 $current_id
		p.link $gdb $current_id 1 $first_loop
	}

	
	$gdb eval {
		delete from links where src = :start;
		delete from vertices where vertex_id in (:start, :end);
	}	

}

proc p.rewire_for { gdb start end parts append_semicolon } {
	set diagram_id [ p.vertex_diagram $gdb $start ]
	unpack $parts init check advance
	set item_id [ p.vertex_item $gdb $start ]
	if { $append_semicolon } {
		append init ";"
		append advance ";"
	}
	set init_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0001 ] "action" $init 0 ]
	set check_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0002 ] "if" $check 0 ]
	set advance_id [ p.insert_vertex $gdb $diagram_id [ append_digits $item_id 0003 ] "action" $advance 0 ]
	p.relink $gdb $end $advance_id
	p.link $gdb $advance_id 1 $check_id
	p.relink $gdb $start $init_id
	p.link $gdb $init_id 1 $check_id
	set first_loop [ p.get_next $gdb $start 2 ]
	set after_loop [ p.get_next $gdb $start 1 ]
	p.link $gdb $check_id 1 $after_loop
	p.link $gdb $check_id 2 $first_loop
	$gdb eval {
		delete from links where src = :start;
		delete from vertices where vertex_id in (:start, :end);
	}	
}

proc extract_sections { text } {
	set lines [ split $text "\n" ]
	set result {}
	set buffer ""
	set current_header ""
	foreach line $lines {
		set header [ p.try_extract_header $line ]
		if { $header != "" } {
			if { $buffer != "" } {
				lappend result $current_header $buffer
				set buffer ""
				set current_header $header
			}
			set current_header $header
		} elseif { $current_header != "" } {
			if { $buffer != "" } {
				append buffer "\n"
			}
			set no_r [ string map { "\r" "" } $line ]
			append buffer $no_r
		}
	}

	if { $buffer != "" } {
		lappend result $current_header $buffer
	}

	return $result
}



proc p.separate_line { text } {
	set first [ string first "//" $text ]
	if { $first == -1 } {
		set part0 $text
		set part1 ""
	} else {
		set part0end [ expr { $first - 1 } ]
		set part1start [ expr { $first + 2 } ]
		set part0 [ string range $text 0 $part0end ]
		set part1 [ string range $text $part1start end ]
	}
	set part0tr [ string trim $part0 ]
	set part1tr [ string trim $part1 ]
	return [ list $part0tr $part1tr ]
}

proc separate_from_comments { text } {
	set row_lines [ split $text "\n" ]
	set lines {}
	foreach row $row_lines {
		set parts [ p.separate_line $row ]
		if { [ lindex $parts 0 ] != "" } {
			lappend lines $parts
		}
	}
	return $lines
}

proc create_signature { fun_type access arguments returns } {
	return [ list $fun_type $access $arguments $returns ]
}

proc extract_return_type { line } {
	set return_length [ string length "returns " ]
	set return_length_1 [ expr { $return_length - 1 } ]
	
	if { [ string range $line 0 $return_length_1 ] == "returns " } {
		set remainder [ string range $line $return_length end ]
		return [ string trim $remainder ]
	}
	
	return ""
}

proc p.contains_return { text } {
	set lines [ split $text "\n" ]
	foreach line $lines {
		if { [ string match "return *" $line ] } { return 1 }
		if { [ string match "throw *" $line ] } { return 1 }
		if { $line == "throw;" } { return 1 }
	}
	return 0
}

proc p.has_connections { gdb vertex_id } {
	set count [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]
	return [ expr { $count > 0 } ]
}

proc p.check_links { gdb } {
	$gdb eval { select src from links } {
		puts "----->src is '$src'"
		if { [ string trim $src ] == "" } {
			error "links without src"
		}
	}
}

proc many_exists { gdb vertex_id } {
	set exits [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]
	return [ expr { $exits > 1 } ]
}

proc one_entry_exit { gdb vertex_id } {
	set entries [ $gdb onecolumn {
		select count(*)
		from links
		where dst = :vertex_id } ]

	set exits [ $gdb onecolumn {
		select count(*)
		from links
		where src = :vertex_id } ]

	return [ expr { $entries == 1 && $exits == 1 } ]
}

proc p.classify_return { text } {
	if { [ p.contains_return $text ] } {
		return has_return
	} else {
		return last_item
	}
}

proc p.scan_vertices { result_list gdb vertices commentor } {
	upvar 1 $result_list result
	foreach vertex_id $vertices {
		unpack [ $gdb eval { select text, type, b, item_id
			from vertices where vertex_id = :vertex_id
		} ] text type b item_id

		if { ![p.has_connections $gdb $vertex_id ] } { continue }
		set text_lines [ split $text "\n" ]
		set body [ list $type $text_lines $b ]
		set links {}
		$gdb eval { select src, ordinal, dst, constant
				from links where src = :vertex_id 
				order by ordinal} {
			set code {}
			if { [ p.vertex_type $gdb $dst ] == "beginend" } {
				set next_item [ p.classify_return $text ]
			} elseif { [ one_entry_exit $gdb $dst ] &&
						[ many_exists $gdb $vertex_id ]} {
				set merged_item [ p.vertex_item $gdb $dst ]
				set code [ list [ $commentor "item $merged_item" ] ]
				set next_text [ p.vertex_text $gdb $dst ]
				foreach line [ split $next_text "\n" ] {
					lappend code $line
				}

				set next_vertex [ p.next_on_skewer $gdb $dst ]
				if { [ p.vertex_type $gdb $next_vertex ] == "beginend" } {
					set next_item [ p.classify_return $next_text ]
				} else {
					set next_item [ p.vertex_item $gdb $next_vertex ]
				}

				$gdb eval {
					update links set dst = :next_vertex 
					where src = :src and ordinal = :ordinal;
					delete from links where src = :dst;
				}
			} else {
				set next_item [ p.vertex_item $gdb $dst ]
			}
			lappend links [ list $next_item $constant $code ]
		}
		lappend result $item_id [ list $body $links ]
	}
}

proc find_start_item { gdb diagram_id } {
	set start_icon [ get_start_icon $gdb $diagram_id ]
	set real_start [ p.next_on_skewer $gdb $start_icon ]
	set start_item [ p.vertex_item $gdb $real_start ]
	
	return $start_item
}

proc generate_nodes { gdb diagram_id commentor } {
	set result {}
	set conditionals [ $gdb eval {
		select vertex_id from vertices 
		where diagram_id = :diagram_id
		and type in ('if', 'select') } ]

	p.scan_vertices result $gdb $conditionals $commentor

	set normals [ $gdb eval {
		select vertex_id from vertices 
		where diagram_id = :diagram_id
		and type not in ('if', 'select', 'beginend' ) } ]

	p.scan_vertices result $gdb $normals $commentor


	set uni {}
	foreach {item_id node} $result {
		if { [ contains $uni $item_id ] } {
			error "$item_id not unique"
		} else {
			lappend uni $item_id
		}
	}

	return $result

}

proc add_line { result line base depth } {
	upvar 1 $result output
	set indent [ make_indent [ expr { $base + $depth } ] ]
	lappend output "$indent$line"
}

proc add_lines { result before lines after base depth } {
	upvar 1 $result output
	set indent [ make_indent [ expr { $base + $depth } ] ]
	set length [ llength $lines ]
	set last [ expr { $length - 1 } ]
	repeat i $length {
		set line [ lindex $lines $i ]

		if { $i == 0 } {
			set line [ join [ list $before $line ] {} ]
		}
		if { $i == $last } {
			append line $after
		}
		
		set line [ join [ list $indent $line ] {} ]
		lappend output $line
	}
}

proc make_indent { depth } {
	set indent ""
	repeat i $depth {
		append indent "    "
	}
	return $indent
}

proc indent { lines depth } {
	set result {}
	set spaces [ make_indent $depth ]

	foreach line $lines {
		lappend result "$spaces$line"
	}

	return [ join $result "\n" ]
}

proc scan_file_description { db section_names } {
	set description [ $db onecolumn {
		select description
		from state
		where row = 1 } ]
	array set sections [ extract_sections $description ]
	
	set result {}
	foreach name $section_names {
		if { [ info exists sections($name) ] } {
			set section $sections($name)
		} else {
			set section ""
		}
		lappend result $section
	}
	return $result
}


proc get_diagram_start { gdb diagram_id } {
	return [ $gdb eval {
		select start_icon, params_icon
		from branches 
		where diagram_id = :diagram_id
			and ordinal = 1
	} ]
}

proc generate_function { db gdb diagram_id callbacks nogoto } {
	set extract_signature [ get_callback $callbacks signature ]
	set generate_body [ get_callback $callbacks body ]
	set commentator [ get_callback $callbacks comment ]
	set enforce_nogoto [ get_optional_callback $callbacks enforce_nogoto ]

	unpack [ $gdb eval {
		select start_icon, params_icon
		from branches 
		where diagram_id = :diagram_id
			and ordinal = 1
	} ] start_icon params_icon

	set name [ $db onecolumn { select name from diagrams where diagram_id = :diagram_id } ]


	if { $params_icon == "" } {
		set params_text ""
	} else {
		set params_text [ $gdb onecolumn {
			select text from vertices where vertex_id = :params_icon } ]
	}

	set signature [ $extract_signature $params_text $name ]
	unpack $signature errorMessage real_sign
	if { $errorMessage != "" } {
		error $errorMessage
	}
	
	set start_item [ find_start_item $gdb $diagram_id ]
	set tree ""
	
	set body ""
	if { $nogoto } {
		set body [ try_nogoto $gdb $diagram_id $callbacks $start_item $name ]
		if { $body == "" && $enforce_nogoto != "" } {
			$enforce_nogoto $name
		}
	}
	
	if { $body == "" } {
		set node_list [ generate_nodes $gdb $diagram_id $commentator ]
		unpack [ sort_items $node_list $start_item ] sorted incoming
		set body [ $generate_body $gdb $diagram_id $start_item $node_list $sorted $incoming]
	}
	
	set declares [ p.get_declares $gdb $diagram_id ]
	set body [ concat $declares $body ]
	
	return [ list $diagram_id $name $real_sign $body ]
}



proc try_nogoto { gdb diagram_id callbacks start_item name } {
	set db "gen-body"
	set start_vertex [ $gdb onecolumn {
		select vertex_id
		from vertices
		where item_id = :start_item } ]
	
	nogoto::create_db $db
	set log [ expr { $name == "xxxx" } ]
	add_to_graph $gdb $db $start_vertex $log
	
	puts "solving: $name"
	set tree [ nogoto::generate $db $start_item ]
		
	if { $tree == "" } {
		puts "could not solve $name, using goto"
		return ""
	}
	
	set inspector [ get_optional_callback $callbacks inspect_tree ]
	if { $inspector != "" } {
		$inspector $tree $name
	}
	
	set result [ print_node $db $tree $callbacks 0 ]
	
	return $result
}


proc get_text_lines { db item_id } {
	return [ $db onecolumn {
		select text_lines
		from nodes
		where item_id = :item_id } ]
}



proc print_node { db node callback depth } {
	set line_end [ get_optional_callback $callback line_end ]
	set commentator [ get_callback $callback comment ]
	set break_str [ get_callback $callback break ]
	set continue_cb [ get_callback $callback continue ]
	set continue_str [ $continue_cb ]
	
	set block_close [ get_callback $callback block_close ]
	set if_start [ get_callback $callback if_start ]
	set if_end [ get_callback $callback if_end ]
	set while_start [ get_callback $callback while_start ]
	set else_start [ get_callback $callback else_start ]
	set pass [ get_callback $callback pass ]
	
	set length [ llength $node ]
	set result {}
	set prev ""
	set indent [ make_indent $depth ]
	set next_depth [ expr { $depth + 1 } ]

	for { set i 1 } { $i < $length } { incr i } {
		set current [ lindex $node $i ]
		if { [ string is integer $current ] } {
			set text [ get_text_lines $db $current ]
			set parts [ split $text "\n" ]
			if { [ llength $parts ] != 0 } {
				append_line_end result $i $line_end			
				set comment [ $commentator "item $current" ]
				lappend result $indent$comment
			}
			
			foreach part $parts {
				set line $indent$part
				lappend result $line
				set prev $part
			}
		} elseif { $current == "break" } {
			if { ![ string match "return*" $prev ] } {
				lappend result $indent$break_str
			}
			set prev ""
		} elseif { $current == "continue" } {
			lappend result $indent$continue_str
			set prev ""
		} elseif { [ lindex $current 0 ] == "if" } {
			append_line_end result $i $line_end
			
			set cond_item [ lindex $current 1 ]
			set cond_text [ get_text_lines $db $cond_item ]
			set comment [ $commentator "item $cond_item" ]
			lappend result $indent$comment
			
			set cond "[ $if_start ]$cond_text[ $if_end ]"
			lappend result $indent$cond
			
			set then_node [ lindex $current 3 ]
			set else_node [ lindex $current 2 ]
			set then [ print_node $db $then_node $callback $next_depth ]
			set result [ concat $result $then ]
			
			lappend result "$indent[ $else_start ]"
			set else [ print_node $db $else_node $callback $next_depth ]
			set result [ concat $result $else ]
			$block_close result $depth

			set prev ""
		} elseif { [ lindex $current 0 ] == "loop" } {
			lappend result "$indent[ $while_start ]"
			set body [ print_node $db $current $callback $next_depth ]
			set result [ concat $result $body ]
			$block_close result $depth
			set prev ""
		} else {
			error "unexpected: $current"
		}
	}
	
	if { $result == "" } {
		set result [ list "$indent[ $pass ]" ]
	}
	
	return $result
}

proc append_line_end { result_list i line_end } {
	upvar 1 $result_list result
	
	if { $line_end == "" } { return }
	if { $i == 1 } { return }	
		
	set result_length [ llength $result ]

	set end_index [ expr { $result_length - 1 } ]
	set end_item [ lindex $result $end_index ]
	append end_item $line_end
	
	set result [ lreplace $result $end_index $end_index $end_item ]
}

proc add_to_graph { gdb ndb vertex_id log } {

	set item_id [ p.vertex_item $gdb $vertex_id ]
	if { [ nogoto::node_exists $ndb $item_id ] } { return }
	set text [ p.vertex_text $gdb $vertex_id ]
	set type [ p.vertex_type $gdb $vertex_id ]
	if { $type == "beginend" } {
		set type "action"
		set text ""
	}
	
	nogoto::insert_node $ndb $item_id $type $text
	if { $log } {
		puts "nogoto::insert_node \$db $item_id $type \{\}"
	}
	
	set ordinals [ $gdb eval {
		select ordinal
		from links
		where src = :vertex_id } ]
		
	set i 0
	foreach ordinal $ordinals {
		set dst [ p.link_dst $gdb $vertex_id $ordinal ]
		set dst_item [ p.vertex_item $gdb $dst ]
		
		nogoto::insert_link $ndb $item_id $i $dst_item normal
		if { $log } {
			puts "nogoto::insert_link \$db $item_id $i $dst_item normal"
		}
		
		incr i
		
		add_to_graph $gdb $ndb $dst $log
	}
}

proc sort_items { node_list start_item } {
	array set nodes $node_list
	set item_ids [ array names nodes ]
	
	if { [ llength $item_ids ] == 0 } {
		return [ list {} {} ]
	}
	
	nsorter::init sortingdb $start_item
	foreach item_id $item_ids {
		nsorter::add_node $item_id
	}
	
	foreach item_id $item_ids {
		set node $nodes($item_id)			
		unpack $node body links
		set i 1
		foreach link $links {
			set dst [ lindex $link 0 ]
			if { $dst != "last_item" && $dst != "has_return" } {
				nsorter::add_link $item_id $i $dst
				incr i
			}
		}
	}
	
	nsorter::complete_construction
	
	set sorted [ nsorter::sort ]
	set incoming [ nsorter::get_incoming_for_nodes ]
	
	return [ list $sorted $incoming ]
}



proc generate_functions { db gdb callbacks nogoto } {

	set result {}
	$db eval {
		select diagram_id
		from diagrams
		order by name
	} {
		if { [ has_branches $gdb $diagram_id ] } {
			lappend result [ generate_function $db $gdb $diagram_id  \
				$callbacks $nogoto ]
		}
	}

	return $result
}

proc p.keywords { } {
	return {
		assign
		compare
		compare2
		while_start
		if_start
		elseif_start
		if_end
		else_start
		pass
		continue
		return_none
		block_close
		comment
		bad_case
		for_init
		for_check
		for_current
		for_incr
		for_declare
		body
		signature
		and
		or
		not
		break
		declare
		line_end
		enforce_nogoto
		inspect_tree
	}
}


proc put_callback { map_name action procedure } {
	upvar 1 $map_name map
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "put_callback: Unknown callback action: $action"
	}
	put_value map $action $procedure
}

proc get_callback { map action } {
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "get_callback: Unknown callback action: $action"
	}
	return [ get_value $map $action ]
}

proc get_optional_callback { map action } {
	set keywords [ p.keywords ]
	if { ![ contains $keywords $action ] } {
		error "get_optional_callback: Unknown callback action: $action"
	}
	set index [ find_key $map $action ]
	if { $index == -1 } { return "" }
	return [ get_value $map $action ]
}


}

