# Commonly used utilities.

proc join_strings { strings } {
	if { $strings == "\{" } { return $strings }
	if { $strings == "\[" } { return $strings }
	if { $strings == "\"" } { return $strings }
	if { $strings == "\(" } { return $strings }

	set result ""
	foreach string $strings {
		set result $result$string
		#append result $string
	}
	return $result
}

proc flag_on { value flag } {
	if { [ expr { $value & $flag } ]  } {
		return 1
	} else {
		return 0
	}
}


proc get_script_path { } {
	return [ file normalize [ info script ] ]
}


proc get_script_dir { } {
	return [ file dirname [ get_script_path ] ]
}

proc read_all_text { filename } {
	set fp [ open $filename r ]
	set data [ read $fp ]
	close $fp
	return $data
}

proc unpack { list args } {
	set i 0
	foreach arg $args {
		set varname v$i
		upvar $arg $varname
		set $varname [ lindex $list $i ]
		incr i
	}
}

proc repeat { i count body } {
	upvar $i j
	for { set j 0 } { $j < $count } { incr j } {
		set result [ catch {
			uplevel $body } ex ]

		if { $result == 3 } { return }
		if { $result != 4 && $result != 0 } { return -code $result $ex }
	}
}

proc zip { left right } {
	set result {}
	foreach litem $left ritem $right {
		lappend result $litem $ritem
	}
	return $result
}

proc wrap { args } {
	return [ list $args ]
}

proc invoke { delegate external } {
  set fun [ lindex $delegate 0 ]
  set args [ lindex $delegate 1 ]
  set result [ $fun $args $external ]
  return $result
}

proc invoke_all { delegates external } {
  foreach delegate $delegates {
    invoke $delegate $external
  }
}

proc vec2.addxy { vec x y } {  
  set x0 [ lindex $vec 0 ]
  set y0 [ lindex $vec 1 ]
  set x1 [ expr { $x0 + $x } ]
  set y1 [ expr { $y0 + $y } ]
  
  return [ list $x1 $y1 ]
}

set utils_logfile ""

proc log { message } {
  global use_log
  if { $use_log } {
    variable utils_logfile
    if { $utils_logfile == "" } {
      set utils_logfile [ open "log.txt" w ]
    }
    puts $message
    puts $utils_logfile $message
  }
}

proc swap { left right } {
  upvar $left left2
  upvar $right right2
  set tmp $left2
  set left2 $right2
  set right2 $tmp
}

proc sweep_rectangle { left top right bottom amount direction } {
	if { $direction == "horizontal" } {
		if { $amount > 0 } {
			set right2 [ expr { $right + $amount } ]
			return [ list $right $top $right2 $bottom ]
		} else {
			set left2 [ expr { $left + $amount } ]
			return [ list $left2 $top $left $bottom ]
		}
	} elseif { $direction == "vertical" } {
		if { $amount > 0 } {
			set bottom2 [ expr { $bottom + $amount } ]
			return [ list $left $bottom $right $bottom2 ]
		} else {
			set top2 [ expr { $top + $amount } ]
			return [ list $left $top2 $right $top ]
		}	
	} else {
		error "Bad direction: $direction"
	}
}



proc rectangles_on_axis { left0 top0 right0 bottom0 
	left1 top1 right1 bottom1 orientation } {
	
	if { ![ rectangles_intersect $left0 $top0 $right0 $bottom0 \
		$left1 $top1 $right1 $bottom1 ] } {
		
		return 0
	}
	if { $orientation == "horizontal" } {
		set axis0 [ expr { ($top0 + $bottom0) / 2 } ]
		set axis1 [ expr { ($top1 + $bottom1) / 2 } ]
	} elseif { $orientation == "vertical" } {
		set axis0 [ expr { ($left0 + $right0) / 2 } ]
		set axis1 [ expr { ($left1 + $right1) / 2 } ]	
	} else {
		error "Unexpected orientation: $orientation"
	}
	
	return [ expr { $axis0 == $axis1 } ]
}

proc touching_side { left0 top0 right0 bottom0 
	left1 top1 right1 bottom1 direction } {
	
	if { ![ rectangles_intersect $left0 $top0 $right0 $bottom0 \
		$left1 $top1 $right1 $bottom1 ] } {
		
		return none
	}

	if { $direction == "vertical" } {
		if { $top1 < $top0 && $bottom1 <= $bottom0 } {
			return less
		} elseif { $top1 >= $top0 && $bottom1 > $bottom0 } {
			return greater
		} else {
			return none
		}
	} elseif { $direction == "horizontal" } {
		if { $left1 < $left0 && $right1 <= $right0 } {
			return less
		} elseif { $left1 >= $left0 && $right1 > $right0 } {
			return greater
		} else {
			return none
		}
	} else {
		error "Unexpected direction: $direction"
	}
}

proc push_rect { left0 top0 right0 bottom0 
	left1 top1 right1 bottom1 
	direction delta } {

	if { ![ rectangles_intersect $left0 $top0 $right0 $bottom0 \
		$left1 $top1 $right1 $bottom1 ] } {
		return 0
	}
		
	if { $direction == "horizontal" } {
		if { $delta > 0 } {
			return [ expr { $right0 - $left1 + 10 } ]
		} else {
			return [ expr { $left0 - $right1 - 10 } ]
		}
	} elseif { $direction == "vertical" } {
		if { $delta > 0 } {
			return [ expr { $bottom0 - $top1 + 10 } ]
		} else {
			return [ expr { $top0 - $bottom1 - 10 } ]
		}
	} else {
		error "Unexpected direction: $direction"
	}
}

proc rectangles_intersect { left0 top0 right0 bottom0 left1 top1 right1 bottom1 } {
  if { $left0 > $right1 } { return 0 }
  if { $left1 > $right0 } { return 0 }
  if { $top0 > $bottom1 } { return 0 }
  if { $top1 > $bottom0 } { return 0 } 
  return 1  
}

proc hit_rectangle { rect x y } {
  set left [ lindex $rect 0 ]
  set top [ lindex $rect 1 ]
  set right [ lindex $rect 2 ]
  set bottom [ lindex $rect 3 ]
  
  if { $x < $left } { return 0 }
  if { $x > $right } { return 0 }
  if { $y < $top } { return 0 }
  if { $y > $bottom } { return 0 }
  
  return 1
}

proc add_border { rect border } {
	
	set left [ lindex $rect 0 ]
	set top [ lindex $rect 1 ]
	set right [ lindex $rect 2 ]
	set bottom [ lindex $rect 3 ]
	
	set left2 [ expr { $left - $border } ]
	set right2 [ expr { $right + $border } ]
	set top2 [ expr { $top - $border } ]
	set bottom2 [ expr { $bottom + $border } ]
	set rect2 [ list $left2 $top2 $right2 $bottom2 ]
	
	return $rect2
}

proc move_rectangle { rect dx dy } {
	set left [ lindex $rect 0 ]
	set top [ lindex $rect 1 ]
	set right [ lindex $rect 2 ]
	set bottom [ lindex $rect 3 ]
  
	set left2 [ expr { $left + $dx } ]
	set right2 [ expr { $right + $dx } ]
	set top2 [ expr { $top + $dy } ]
	set bottom2 [ expr { $bottom + $dy } ]
	
	set rect2 [ list $left2 $top2 $right2 $bottom2 ]
	
	return $rect2
}


proc make_rect { x y w h } {
	set left [ expr { $x - $w } ]
	set right [ expr { $x + $w } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set rect [ list $left $top $right $bottom ]
	
	return $rect
}

proc snap_up { value } {
	set snap_size 10
	set result [ expr { int(ceil(double($value) / double($snap_size))) * $snap_size } ]
	if { $result == 0 } { return $snap_size }
	return $result
}


proc snap { value grid } {
	return [ expr { int($value) / int($grid) * int($grid) } ]
}

proc get_argument { arguments fun name } {
	upvar $arguments arg_array
	if { ![ info exists arg_array($name) ] } {
		error "$fun: missing argument $name"
	}
	
	return $arg_array($name)
}

proc get_optional_argument { arguments name } {
	upvar $arguments arg_array
	if { ![ info exists arg_array($name) ] } {
		return ""
	}
	
	return $arg_array($name)
}

proc map { args } {
	array set arguments $args
	set collection [ get_argument arguments map -list ]
	set fun [ get_argument arguments map -fun ]
	set result {}
	foreach item $collection {
		lappend result [ $fun $item ]
	}
	return $result
}


proc filter { args } {
	array set arguments $args
	set collection [ get_argument arguments map -list ]
	set fun [ get_argument arguments map -fun ]
	set result {}
	foreach item $collection {
		if { [ $fun $item ] } {
			lappend result $item
		}
	}
	return $result
}

proc lfilter { list fun } {
	set result {}
	foreach item $list {
		if { [ $fun $item ] } {
			lappend result $item
		}
	}
	return $result	
}

proc lfilter_user { list fun user } {
	set result {}
	foreach item $list {
		if { [ $fun $item $user ] } {
			lappend result $item
		}
	}
	return $result	
}


proc snap_coord { coord } {
	set snap_size 10
	return [ snap $coord $snap_size ]
}

proc snap_delta { delta } {
	if { $delta < 0 } {
		set mdelta [ expr { -$delta } ]
		set result [ snap_coord $mdelta ]
		return [ expr { -$result } ]
	} else {
		return [ snap_coord $delta ]
	}
}

proc snap_coords { coords } {
	return [ map -list $coords -fun snap_coord ]
}

proc sql_escape { text } {
	return [ string map { "'" "''" "\r" "" } $text ]
}


proc make_char_set { texts } {
  array set chars {}
  foreach text $texts {
    set length [ string length $text ]
    repeat i $length {
      set char [ string index $text $i ]
      set code [ scan $char %c ]
      if { ![ info exists chars($code) ] } {
        set chars($code) 1
      }
    }
  }
  set char_list [ array names chars ]
  return [ lsort -dictionary $char_list ]
}

proc intervals_touch { aleft aright bleft bright } {
	if { $aright < $bleft } { return  { 0 0 0 } }
	if { $bright < $aleft } { return  { 0 0 0 } }
	
	if { $aleft < $bleft } {
		set left $aleft
	} else {
		set left $bleft
	}
	
	if { $aright > $bright } {
		set right $aright
	} else {
		set right $bright
	}
	
	return [ list 1 $left $right ]
}

proc intervals_intersect { ax1 ax2 bx1 bx2 } {
	if { $ax2 < $bx1 } { return 0 }
	if { $bx2 < $ax1 } { return 0 }
	if { $ax1 < $bx1 } {
		if { $ax2 == $bx1 } {
			return 0
		} else {
			return 1
		}
	} else {
		if { $ax1 == $bx2 } {
			return 0
		} else {
			return 1
		}
	}
}

proc line_hit_box { rect point1 point2 } {
	set x1 [ lindex $point1 0 ]
	set y1 [ lindex $point1 1 ]
	set x2 [ lindex $point2 0 ]
	set y2 [ lindex $point2 1 ]
	set left [ lindex $rect 0 ]
	set top [ lindex $rect 1 ]
	set right [ lindex $rect 2 ]
	set bottom [ lindex $rect 3 ]
	if { $x1 < $left && $x2 < $left } { return 0 }
	if { $x1 > $right && $x2 > $right } { return 0 }
	if { $y1 < $top && $y2 < $top } { return 0 }
	if { $y1 > $bottom && $y2 > $bottom } { return 0 }
	return 1
}

proc box_cut_line_vertical { rect point1 point2 } {
	set x1 [ lindex $point1 0 ]
	set y1 [ lindex $point1 1 ]
	set y2 [ lindex $point2 1 ]
	set top [ lindex $rect 1 ]
	set bottom [ lindex $rect 3 ]
	set result {}
	if { $y1 < $top } {
		set p1 [ list $x1 $y1 ]
		set p2 [ list $x1 $top ]
		lappend result [ list 2 $p1 $p2 ]
	}
	if { $y2 > $bottom } {
		set p1 [ list $x1 $bottom ]
		set p2 [ list $x1 $y2 ]
		lappend result [ list 1 $p1 $p2 ]	
	}
	return $result
}

proc box_cut_line_horizontal { rect point1 point2 } {
	set x1 [ lindex $point1 0 ]
	set y1 [ lindex $point1 1 ]
	set x2 [ lindex $point2 0 ]
	set left [ lindex $rect 0 ]
	set right [ lindex $rect 2 ]
	set result {}
	if { $x1 < $left } {
		set p1 [ list $x1 $y1 ]
		set p2 [ list $left $y1 ]
		lappend result [ list 2 $p1 $p2 ]
	}
	if { $x2 > $right } {
		set p1 [ list $right $y1 ]
		set p2 [ list $x2 $y1 ]
		lappend result [ list 1 $p1 $p2 ]	
	}
	return $result
}


proc intersect_lines_leftright { mpoint1 mpoint2 bpoint1 bpoint2 } {
	set mx [ lindex $mpoint1 0 ]
	set my1 [ lindex $mpoint1 1 ]
	set my2 [ lindex $mpoint2 1 ]
	
	set by [ lindex $bpoint1 1 ]
	set bx1 [ lindex $bpoint1 0 ]
	set bx2 [ lindex $bpoint2 0 ]
	
	if { $by <= $my1 || $by >= $my2 } {
		return { none bad bad }
	}
	
	if { $bx1 > $mx || $bx2 < $mx }  {
		return { none bad bad }
	}
	
	if { $bx1 < $mx && $bx2 > $mx } {
		return [ list crossing_lr $mx $by ]
	}
	
	if { $bx1 < $mx } {
		return [ list left $mx $by ]
	} else {
		return [ list right $mx $by ]
	}
}


proc intersect_lines_updown { mpoint1 mpoint2 bpoint1 bpoint2 } {
	set my [ lindex $mpoint1 1 ]
	set mx1 [ lindex $mpoint1 0 ]
	set mx2 [ lindex $mpoint2 0 ]
	
	set bx [ lindex $bpoint1 0 ]
	set by1 [ lindex $bpoint1 1 ]
	set by2 [ lindex $bpoint2 1 ]
	
	if { $bx <= $mx1 || $bx >= $mx2 } {
		return { none bad bad }
	}
	
	if { $by1 > $my || $by2 < $my }  {
		return { none bad bad }
	}
	
	if { $by1 < $my && $by2 > $my } {
		return [ list crossing_ud $bx $my ]
	}
	
	if { $by1 < $my } {
		return [ list up $bx $my ]
	} else {
		return [ list down $bx $my ]
	}
}

proc contains { list element } {
	set found [ lsearch -exact $list $element ]
	return [ expr { $found != -1 } ]
}

proc remove { list element } {
	set found [ lsearch -exact $list $element ]
	if { $found == -1 } {
		return $list
	} else {
		return [ lreplace $list $found $found ]
	}
}

proc print_table { db table } {
	set sql "select * from $table"
	puts "\n\n$sql"
	puts "-----------"
	$db eval $sql row {
		parray row
		puts ""
	}
	set count [ $db onecolumn "select count(*) from $table" ]
	puts "$count record(s)."
	puts "-----------"	
}

proc init_cap { text } {
	set result ""
	set length [ string length $text ]
	repeat i $length {
		set c [ string index $text $i ]
		if { $i == 0 } {
			set c [ string toupper $c ]
		} else {
			set c [ string tolower $c ]
		}
		append result $c
	}
	return $result
}


proc replace_extension { filename new_extension } {
	set tail [ file tail $filename ]
	set last [ string last "." $tail ]
	if { $last == -1 } {
		return "$filename.$new_extension"
	}

	set cut_tail [ string range $tail 0 $last ]
	set dir [ file dirname $filename ]
	return [ join [ list $dir "/" $cut_tail $new_extension ] "" ]
}

proc open_files { filenames mode } {
	set handles {}
	foreach filename $filenames {
		if { [ catch {
			set handle [ open $filename $mode ]
			lappend handles $handle
		} message ] } {
			close_files $handles
			error $message
		}
	}
		
	return $handles
}

proc close_files { handles } {
	foreach handle $handles {
		catch { close $handle }
	}
}

proc non_empty_lines { lines } {
	set result {}
	foreach line $lines {
		set trimmed [ string trim $line ]
		if { $trimmed != "" } {
			lappend result $line
		}
	}
	return $result
}

proc line_count { text } {
	set lines [ split $text "\n" ]
	set result 0
	foreach line $lines {
		set trimmed [ string trim $line ]
		if { $trimmed != "" } {
			incr result
		}
	}
	return $result
}


proc load_sqlite { } {
	if { [catch {
		package require sqlite3
	} require_failed ] } {

		set soPath /usr/lib/tcltk/sqlite3/libtclsqlite3.so
		if { [catch {
			load $soPath Sqlite3
		} load_failed ] } {

		puts $require_failed
		puts "Fallback also failed:\ncould not load $soPath"

		puts "This script requires sqlite3 package."
		puts "Consider installing libsqlite3-tcl"
		exit
		}
	}
}

proc generate_structure { name fields } {
	set ctr_args {}
	set return_body "return \[ list "
	set i 0
	foreach field_name $fields {
		lappend ctr_args $field_name
		append return_body "\$$field_name "
		generate_getter $name $field_name $i
		generate_setter $name $field_name $i

		incr i
	}
	append return_body "\]"
	set ctr_name "create_$name"
	proc $ctr_name $ctr_args $return_body
}

proc generate_getter { name field_name ordinal } {
	set proc_name "get_${name}_${field_name}"
	set return_line "return \[ lindex \$$name $ordinal \]"
	proc $proc_name [ list $name ] $return_line
}

proc generate_setter { name field_name ordinal } {
	set proc_name "set_${name}_${field_name}"
	set return_line "return \[ lreplace \$$name $ordinal $ordinal \$$field_name \]"
	proc $proc_name [ list $name $field_name ] $return_line
}

proc get_value { map key } {
	set index [ find_key $map $key ]
	if { $index == -1 } {
		error "Key '$key' not found in map: $map"
	}
	
	incr index
	return [ lindex $map $index ]
}

proc find_key { map key } {
	set length [ llength $map ]
	for { set i 0 } { $i < $length } { incr i 2 } {
		set ckey [ lindex $map $i ]
		if { $ckey == $key } {
			return $i
		}
	}
	return -1
}

proc put_value { map_name key value } {
	upvar 1 $map_name map
	set index [ find_key $map $key ]
	if { $index == -1 } {
		lappend map $key $value
	} else {
		incr index
		set map [ lreplace $map $index $index $value ]
	}
}

proc have_intersection { left right } {
	foreach lefti $left {
		if { [ contains $right $lefti ] } {
			return 1
		}
	}
	return 0
}

proc is_variable { text } {
	set trimmed [ string trim $text ]
	set length [ string length $trimmed ]
	for { set i 0 } { $i < $length } { incr i } {
		set c [ string index $trimmed $i ]
		if { [ string is alnum $c ] || $c == "\$" || $c == "_" } {
			continue
		} else {
			return 0
		}
	}
	return 1
}
