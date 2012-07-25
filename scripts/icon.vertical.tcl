namespace eval mv {

proc vertical.switch { } {
	return ""
}

proc vertical.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'vertical'			\
		text					""			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						0					\
		h						100					\
		a						0					\
		b						0		 ]
}

proc vertical.lines { x y w h a b } {
	set coords [ list $x $y $x [ expr $y + $h ] ]
	set cdbox [ add_handle_border $coords ]
	set line [ make_prim main line $coords "" "" "#000000" $cdbox ]
	return [ list $line ]
}

proc vertical.icons { text xx y w h a b } {
	return {}
}

proc vertical.fit { tw th x y w h a b } {
	return [ list $x $y $w $h $a $b ]
}


proc vertical.handles { x y w h a b } {
	set bottom [ expr { $y + $h } ]
	
	set top			[ make_vertex top	$x $y ]
	set bottom		[ make_vertex bottom	$x $bottom ]	

	return [ list $top $bottom ]
}

proc vertical.top { dx dy x y w h a b } {
  set h2 [ expr { $h - $dy } ]
  if { $h2 < 20 } { set h2 20 }
  set y2 [ expr { $y + $h - $h2 } ]
  set x2 [ expr { $x + $dx } ]
  return [ list $x2 $y2 $w $h2 $a $b ]
}


proc vertical.bottom { dx dy x y w h a b } {
  set h2 [ expr { $h + $dy } ]
  if { $h2 < 20 } { set h2 20 }
  set x2 [ expr { $x + $dx } ]  
  return [ list $x2 $y $w $h2 $a $b ]
}

}