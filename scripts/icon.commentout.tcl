
namespace eval mv {

proc commentout.switch { } {
	return "Flip horizontally"
}

proc commentout.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'commentout'			\
		text					comment-out			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						60					\
		a						60					\
		b						0		 ]
}

proc commentout.fit { tw th x y w h a b } {
	return [ action.fit $tw $th $x $y $w $h $a $b ]
}


proc commentout.lines { x y w h a b } {
	if { $b == 1 } {
		set left [ expr { $x + $w } ]
		set right [ expr { $left + $a } ]
	} else {
		set right [ expr { $x - $w } ]	
		set left [ expr { $right - $a } ]
	}
	set coords [ list $left $y $right $y ]
	set cdbox [ add_handle_border $coords ]	
	set line [ make_prim branch line $coords "" "" "#000000" $cdbox ]
	return [ list $line ]
}

proc commentout.icons { text x y w h a b } {
	set margin 10
	set w2 [ expr { $w - $margin } ]
	set h2 [ expr { $h - $margin } ]
	set inner_coords [ make_rect $x $y $w2 $h2 ]
	
	set left [ expr { $x - $w } ]
	set right [ expr { $x + $w } ]
	set top [ expr { $y - $h } ]
	set bottom [ expr { $y + $h } ]
	
	if { $b == 1 } {
		set frame_coords [ list $left $bottom   $right $bottom   $right $top   $left $top ]	
	} else {
		set frame_coords [ list $right $bottom   $left $bottom   $left $top   $right $top ]
	}
	
	set rect_coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $rect_coords ]
	
	set rect [ make_prim main rectangle $inner_coords "" "#ffffff" "#ffffff" $cdbox ]
	set frame [ make_prim frame line $frame_coords "" "" "#000000" $cdbox ]
	set text_prim [ create_text $x $y $text ]
	
	return [ list $rect $frame $text_prim ]
}


proc commentout.handles { x y w h a b } {
	set result [ action.handles $x $y $w $h $a $b ]
	if { $b == 0 } {
		set side [ expr { $x - $w - $a } ]
	} else {
		set side [ expr { $x + $w + $a } ]
	}
	set branch_handle [ make_vertex branch_handle $side $y ]
	lappend result $branch_handle
	return $result
}

proc commentout.branch_handle { dx dy x y w h a b } {
	if { $b == 0 } {
		set a2 [ expr $a - $dx ]
	} else {
		set a2 [ expr $a + $dx ]
	}
	
	if { $a2 < 20 } { set a2 20 }
	return [ list $x $y $w $h $a2 $b ]
}

proc commentout.nw { dx dy x y w h a b } {
	return [ action.nw $dx $dy $x $y $w $h $a $b ]
}

proc commentout.n { dx dy x y w h a b } {
	return [ action.n $dx $dy $x $y $w $h $a $b ]
}

proc commentout.ne { dx dy x y w h a b } {
	return [ action.ne $dx $dy $x $y $w $h $a $b ]
}

proc commentout.e { dx dy x y w h a b } {
	return [ action.e $dx $dy $x $y $w $h $a $b ]
}

proc commentout.sw { dx dy x y w h a b } {
	return [ action.sw $dx $dy $x $y $w $h $a $b ]
}

proc commentout.s { dx dy x y w h a b } {
	return [ action.s $dx $dy $x $y $w $h $a $b ]
}

proc commentout.se { dx dy x y w h a b } {
	return [ action.se $dx $dy $x $y $w $h $a $b ]
}

proc commentout.w { dx dy x y w h a b } {
	return [ action.w $dx $dy $x $y $w $h $a $b ]
}


}
