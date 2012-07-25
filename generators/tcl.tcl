
gen::add_generator Tcl gen_tcl::generate

namespace eval gen_tcl {







proc p.jump { item_id base depth} {
	set indent [ gen::make_indent [ expr { $base + $depth } ] ]
	if { $item_id == "last_item" } {
		set value "return \"\""
	} elseif { $item_id == "has_return" } {
		set value ""
	} else {
		set value "set _next_item_ $item_id"
	}
	return "$indent$value"
}


proc foreach_init { item_id first second } {
	set index_var "_ind$item_id"
	set coll_var "_col$item_id"
	set length_var "_len$item_id"
	return "set $coll_var $second\nset $length_var \[ llength \$$coll_var \]\nset $index_var 0"
}

proc foreach_check { item_id first second } {
	set index_var "_ind$item_id"
	set coll_var "_col$item_id"
	set length_var "_len$item_id"
	return "\$$index_var < \$$length_var"
}

proc foreach_current { item_id first second } {
	set index_var "_ind$item_id"
	set coll_var "_col$item_id"
	set length_var "_len$item_id"
	return "set $first \[ lindex \$$coll_var \$$index_var \]"
}

proc foreach_incr { item_id first second } {
	set index_var "_ind$item_id"
	return "incr $index_var"
}

proc make_callbacks { } {
	set callbacks {}
	
	gen::put_callback callbacks assign			gen_tcl::p.assign
	gen::put_callback callbacks compare			gen_tcl::p.compare
	gen::put_callback callbacks compare2		gen_tcl::p.compare2
	gen::put_callback callbacks while_start 	gen_tcl::p.while_start
	gen::put_callback callbacks if_start		gen_tcl::p.if_start
	gen::put_callback callbacks elseif_start	gen_tcl::p.elseif_start
	gen::put_callback callbacks if_end			gen_tcl::p.if_end
	gen::put_callback callbacks else_start		gen_tcl::p.else_start
	gen::put_callback callbacks pass			gen_tcl::p.pass
	gen::put_callback callbacks continue		gen_tcl::p.continue
	gen::put_callback callbacks return_none		gen_tcl::p.return_none
	gen::put_callback callbacks block_close		gen_tcl::p.block_close
	gen::put_callback callbacks comment			gen_tcl::p.comment
	gen::put_callback callbacks bad_case		gen_tcl::p.bad_case
	gen::put_callback callbacks for_init		gen_tcl::foreach_init
	gen::put_callback callbacks for_check		gen_tcl::foreach_check
	gen::put_callback callbacks for_current		gen_tcl::foreach_current
	gen::put_callback callbacks for_incr		gen_tcl::foreach_incr
	gen::put_callback callbacks body			gen_tcl::generate_body
	gen::put_callback callbacks signature		gen_tcl::extract_signature
	gen::put_callback callbacks and				gen_tcl::p.and
	gen::put_callback callbacks or				gen_tcl::p.or
	gen::put_callback callbacks not				gen_tcl::p.not
	gen::put_callback callbacks break			"break"
	gen::put_callback callbacks declare			gen_tcl::p.declare
	gen::put_callback callbacks for_declare		gen_tcl::for_declare
	

	return $callbacks
}

proc p.declare { type name value } {
	return ""
}

proc generate_body { gdb diagram_id start_item node_list sorted incoming } {
	set callbacks [ make_callbacks ]
	return [ cbody::generate_body $gdb $diagram_id $start_item $node_list \
		$sorted $incoming $callbacks ]
}

proc p.and { left right } {
	return "($left) && ($right)"
}

proc p.or { left right } {
	return "($left) || ($right)"
}

proc p.not { operand } {
	return "!($operand)"
}

proc p.assign { variable value } {
	return "set $variable $value"
}

proc p.compare { variable value } {
	return "\$$variable == $value"
}

proc p.compare2 { variable value } {
	return "$variable == $value"
}


proc p.while_start { } {
	return "while \{ 1 \} \{"
}

proc p.if_start { } {
	return "if \{"
}

proc p.elseif_start { } {
	return "\} elseif \{"
}

proc p.if_end { } {
	return "\} \{"
}

proc p.else_start { } {
	return "\} else \{"
}
proc p.pass { } {
	return ""
}

proc p.continue { } {
	return "continue"
}

proc p.return_none { } {
	return "return \{\}"
}

proc p.block_close { output depth } {
	upvar 1 $output result
	set line [ gen::make_indent $depth ]
	append line "\}"
	lappend result $line
}

proc p.comment { line } {
	return "#$line"
}

proc p.bad_case { switch_var } {
	return "error \"Unexpected switch value: \$$switch_var\""
}

proc for_declare { item_id first second } {
	return ""
}

proc generate { db gdb filename } {
	set callbacks [ make_callbacks ]

	gen::fix_graph $gdb $callbacks 0
	unpack [ gen::scan_file_description $db { header footer } ] header footer

	set use_nogoto 1
	set functions [ gen::generate_functions $db $gdb $callbacks $use_nogoto ]

	if { [ graph::errors_occured ] } { return }


	set hfile [ replace_extension $filename "tcl" ]
	set f [ open $hfile w ]
	catch {
		p.print_to_file $f $functions $header $footer
	} error_message

	catch { close $f }
	if { $error_message != "" } {
		error $error_message
	}
}

proc build_declaration { name signature } {
	unpack $signature type access parameters returns
	set result "proc $name \{"
	foreach parameter $parameters {
		append result " " [ lindex $parameter 0 ]
	}
	return "$result \} \{"
}

proc p.print_to_file { fhandle functions header footer } {
	if { $header != "" } {
		puts $fhandle $header
	}
	set version [ version_string ]
	puts $fhandle \
	    "# Autogenerated with DRAKON Editor $version"


	foreach function $functions {
		unpack $function diagram_id name signature body
		set type [ lindex $signature 0 ]
		if { $type != "comment" } {
			puts $fhandle ""
			set declaration [ build_declaration $name $signature ]
			puts $fhandle $declaration
			set lines [ gen::indent $body 1 ]
			puts $fhandle $lines
			puts $fhandle "\}"
		}
	}
	puts $fhandle ""
	puts $fhandle $footer
}



proc extract_signature { text name } {
	set lines [ gen::separate_from_comments $text ]
	set first_line [ lindex $lines 0 ]
	set first [ lindex $first_line 0 ]
	if { $first == "#comment" } {
		return [ list {} [ gen::create_signature "comment" {} {} {} ]]
	}

	set parameters {}
	foreach current $lines {
		lappend parameters $current
	}

	return [ list {} [ gen::create_signature procedure public $parameters "" ] ]
}

}

