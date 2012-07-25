namespace eval mv {

proc horizontal.switch { } {
	return ""
}

proc horizontal.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'horizontal'			\
		text					""			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						0					\
		a						0					\
		b						0		 ]
}

proc horizontal.fit { tw th x y w h a b } {
	return [ list $x $y $w $h $a $b ]
}


proc horizontal.lines { x y w h a b } {
	set left $x
	set right [ expr { $x + $w } ]
	set coords [ list $left $y $right $y ]
	set cdbox [ add_handle_border $coords ]
	set line [ make_prim main line $coords "" "" "#000000" $cdbox ]
	return [ list $line ]
}

proc horizontal.icons { text xx y w h a b } {
	return {}
}


proc horizontal.handles { x y w h a b } {
	set left_coord $x
	set right_coord [ expr { $x + $w } ]
	
	set left			[ make_vertex left	$left_coord $y ]
	set right			[ make_vertex right $right_coord $y ] 

	return [ list $left $right ]
}

proc horizontal.left { dx dy x y w h a b } {
	set w2 [ expr { $w - $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set x2 [ expr { $x + $w - $w2 } ]
	set y2 [ expr { $y + $dy } ]
	return [ list $x2 $y2 $w2 $h $a $b ]
}


proc horizontal.right { dx dy x y w h a b } {
	set w2 [ expr { $w + $dx } ]
	if { $w2 < 20 } { set w2 20 }
	set y2 [ expr { $y + $dy } ]
	return [ list $x $y2 $w2 $h $a $b ]
}

}