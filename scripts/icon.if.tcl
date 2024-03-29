
namespace eval mv {

proc if.switch { } {
	return "Swap YES and NO"
}

proc if.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'if'			\
		text					if			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						60					\
		b						0		 ]
}

proc if.lines { x y w h a b } {
	set left [ expr { $x + $w } ]
	set right [ expr { $left + $a } ]
	set coords [ list $left $y $right $y ]
	set cdbox [ add_handle_border $coords ]	
	set line [ make_prim branch line $coords "" "" "#000000" $cdbox ]
	return [ list $line ]
}

proc create_text { x y text { role text } } {
	set text_coords [ list $x $y ]
	set text_cd [ list $x $y $x $y ]
	set text_prim [ make_prim $role text $text_coords $text "" "#000000" $text_cd ]
	return $text_prim
}

proc right_branch_label { x y w text } {
	set width [ mw::main_font_measure "YES" ]
	set cx [ expr { $x + $w + $width * 0.8 } ]
	set cy [ expr { $y - $width * 0.5 } ]
	return [ create_text $cx $cy $text right_label ]
}

proc bottom_branch_label { x y h text } {
	set width [ mw::main_font_measure "YES" ]
	set cx [ expr { $x - $width } ]
	set cy [ expr { $y + $h + $width * 0.5 } ]
	return [ create_text $cx $cy $text bottom_label ]
}

proc if.fit { tw th x y w h a b } {
	set result [ action.fit $tw $th $x $y $w $h $a $b ]
	unpack $result x2 y2 w2 h2 a2 b2
	set aw [ expr { $w + $a } ]
	incr w2 $h2
	set a2 [ expr { $aw - $w2 } ]
	if { $a2 < 20 } { set a2 20 }
	return [ list $x2 $y2 $w2 $h2 $a2 $b2 ]
}


proc if.icons { text x y w h a b } {
	
	set x0 [ expr { $x - $w } ]
	set x1 [ expr { $x0 + $h } ]
	if { $x1 > $x } { set x1 $x }
	set x3 [ expr { $x + $w } ]
	set x2 [ expr { $x3 - $h } ]
	if { $x2 < $x } { set x2 $x }
	
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	
	set coords [ list $x0 $y  $x1 $top  $x2 $top  $x3 $y  $x2 $bottom  $x1 $bottom $x0 $y ]	
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	set rect [ make_prim main polygon $coords "" "#000000" "#ffffb0" $cdbox ]
	set text_prim [ create_text $x $y $text ]

	if { $b == 0 } {
		set right [ right_branch_label $x $y $w YES ]
		set bottom [ bottom_branch_label $x $y $h NO ]
	} else {
		set right [ right_branch_label $x $y $w NO ]
		set bottom [ bottom_branch_label $x $y $h YES ]
	}	
	return [ list $rect $text_prim $right $bottom ]
}


proc if.handles { x y w h a b } {
	set result [ action.handles $x $y $w $h $a $b ]
	set right [ expr { $x + $w + $a } ]
	set branch_handle [ make_vertex branch_handle $right $y ]
	lappend result $branch_handle
	return $result
}

proc if.branch_handle { dx dy x y w h a b } {
	set a2 [ expr $a + $dx ]
	if { $a2 < 20 } { set a2 20 }
	set y2 [ expr { $y + $dy } ]
	return [ list $x $y2 $w $h $a2 $b ]
}

proc if.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc if.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc if.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc if.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc if.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc if.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc if.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc if.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}
