
namespace eval mv {

proc case.switch { } {
	return ""
}

proc case.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'case'		\
		text					case		\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc case.lines { x y w h a b } {
	return {}
}

proc case.fit { tw th x y w h a b } {
	return [ action.fit $tw $th $x $y $w $h $a $b ]
}

proc case.icons { text x y w h a b } {
	set h2 [ expr { $h / 1.5 } ]
	set middle [ expr { $y + $h - $h2 } ]
	set left [ expr { $x - $w } ]
	set right [ expr { $x + $w } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	set coords [ list $left $middle  $left $top  $right $top  $right $middle  $x $bottom  $left $middle ]
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set rect [ make_prim main polygon $coords "" "#000000" "#ffe0d0" $cdbox ]
	set ty [ expr { $top + ( $middle - $top ) / 2 } ]
	set hline [ make_line hline $left $middle $right $middle ]
	set text_prim [ create_text $x $ty $text ]
	return [ list $rect $hline $text_prim ]
}


proc case.handles { x y w h a b } {
	return [ action.handles $x $y $w $h $a $b ]
}

proc case.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc case.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc case.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc case.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc case.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc case.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc case.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc case.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}




proc divide_arc { radius number } {
	global pi
	set result { 0 }
	set small_angle [ expr $pi / 2.0 / $number ]
	for { set i 1 } { $i < $number } { incr i } {
		set angle [ expr $small_angle * $i ]
		set x [ expr (1.0 - cos($angle)) * $radius ]
		lappend result $x
	}
	lappend result $radius
	return $result
}

proc arc_nw { left top height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	
	for { set i 0 } { $i < $number } { incr i } {
		set x0 [ lindex $subdivs $i ]
		set yi [ expr $number - $i ]
		set y0 [ lindex $subdivs $yi ]
		set x [ expr $x0 + $left ]
		set y [ expr $y0 + $top ]
		lappend result $x $y
	}
	return $result
}

proc arc_ne { left top width height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	set right [ expr $left + $width ]
	
	for { set i 0 } { $i < $number } { incr i } {
		set xi [ expr $number - $i ]
		set x0 [ lindex $subdivs $xi ]
		set y0 [ lindex $subdivs $i ]
		set x [ expr $right - $x0 ]
		set y [ expr $y0 + $top ]
		lappend result $x $y
	}
	return $result
}


proc arc_se { left top width height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	set right [ expr $left + $width ]
	
	for { set i 0 } { $i < $number } { incr i } {
		set x0 [ lindex $subdivs $i ]
		set yi [ expr $number - $i ]
		set y0 [ lindex $subdivs $yi ]
		set x [ expr $right - $x0 ]
		set y [ expr $top + $height - $y0 ]
		lappend result $x $y
	}
	return $result
}


proc arc_sw { left top height number } {
	set radius [ expr $height / 2.0 ]
	set subdivs [ divide_arc $radius $number ]
	set result {}
	
	for { set i 0 } { $i < $number } { incr i } {
		set xi [ expr $number - $i ]
		set x0 [ lindex $subdivs $xi ]
		set y0 [ lindex $subdivs $i ]
		set x [ expr $x0 + $left ]
		set y [ expr $top + $height - $y0 ]
		lappend result $x $y
	}
	return $result
}


proc rounded_outline { left top width height number } {
	set nw [ arc_nw $left $top $height $number ]
	set ne [ arc_ne $left $top $width $height $number ]
	set se [ arc_se $left $top $width $height $number ]	
	set sw [ arc_sw $left $top $height $number ]
	
	set x0 $left
	set x1 [ expr $left + $height / 2.0 ]
	set x2 [ expr $left + $width - $height / 2.0 ]
	set x3 [ expr $left + $width ]
	set bottom [ expr $top + $height ]
	
	set extent [ expr $height / 5.0 ]
	
	set leto [ list $x1 $top ]

	
	
	set ribo [ list $x2 $bottom ]
	
	set result [ concat $nw $leto   $ne $se   $ribo  $sw ]
}

proc segments_from_height { h } {
	if { $h <= 30 } { return 6 }
	if { $h <= 60 } { return 12 }
	return 16
}

proc rounded_outline_adpt { x y w h } {
	set width [ expr { $w * 2 } ]
	set height [ expr { $h * 2 } ]
	set left [ expr { $x - $w } ]
	set top [ expr { $y - $h } ]
	set number [ segments_from_height $h ]
	set coords [ rounded_outline $left $top $width $height $number ]
	return $coords
}

}

