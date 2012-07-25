
namespace eval mv {
variable min_action_w 20
variable min_action_h 10

proc make_prim { role type coords text line fill rect } {
	return [ list $role $type $coords $text $line $fill $rect ]
}



proc add_handle_border { rect } {
	variable border
	return [ add_border $rect $border ]
}

proc make_vertex { role x y { fill "#00ff00" } } {
	return [ list $role $x $y $fill ]
}

proc action.switch { } {
	return ""
}

proc action.create { item_id diagram_id x y } {
	return [ list insert items				\
		item_id				$item_id		\
		diagram_id		$diagram_id	\
		type					'action'			\
		text					action			\
		selected				1					\
		x						$x					\
		y						$y					\
		w						60					\
		h						20					\
		a						0					\
		b						0		 ]
}

proc action.lines { x y w h a b } {
	return {}
}

proc create_text_left { x y w h text { role text } } {
	set left [ expr { $x - $w + 10 } ]
	set text_coords [ list $left $y ]
	set text_cd [ list $x $y $x $y ]
	set text_prim [ make_prim $role text_left $text_coords $text "" "#000000" $text_cd ]
	return $text_prim
}

proc action.icons { text x y w h a b } {
	set coords [ make_rect $x $y $w $h ]
	set cdbox [ add_handle_border $coords ]
	set rect [ make_prim main rectangle $coords "" "#000000" "#ffffff" $cdbox ]
	set text_prim [ create_text_left $x $y $w $h $text ]
	return [ list $rect $text_prim ]
}


proc action.handles { x y w h a b } {
	set box [ make_rect $x $y $w $h ]
	set left [ lindex $box 0 ]
	set top [ lindex $box 1 ]
	set right [ lindex $box 2 ]
	set bottom [ lindex $box 3 ]
	
	set nw	[ make_vertex nw	$left $top ]
	set n		[ make_vertex n		$x $top ]
	set ne	[ make_vertex ne	$right $top ]
	
	set e		[ make_vertex e		$left $y ]
	set w		[ make_vertex w	$right $y ]

	set sw	[ make_vertex sw	$left $bottom ]
	set s		[ make_vertex s		$x $bottom ]
	set se	[ make_vertex se	$right $bottom ]
	
	return [ list $nw $n $ne  $e $w  $sw $s $se ]
}

proc action.clamp_w { w } {
  variable min_action_w
  if { $w < $min_action_w } {
    return $min_action_w
  }
  return $w
}

proc action.clamp_h { h } {
  variable min_action_h
  if { $h < $min_action_h } {
    return $min_action_h
  }
  return $h
}



proc action.fit { tw th x y w h a b } {
	if { $tw < 50 } { set tw 50 }
	return [ list $x $y $tw $th $a $b ]
}

proc action.nw { dx dy x y w h a b } {
  set w2 [ expr { $w - $dx } ]
  set w2 [ action.clamp_w $w2 ]
  set h2 [ expr { $h - $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w2 $h2 $a $b ]
}

proc action.n { dx dy x y w h a b } {
  set h2 [ expr { $h - $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w $h2 $a $b ]
}

proc action.ne { dx dy x y w h a b } {
  set w2 [ expr { $w + $dx } ]
  set w2 [ action.clamp_w $w2 ]
  set h2 [ expr { $h - $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w2 $h2 $a $b ]
}

proc action.e { dx dy x y w h a b } {
  set w2 [ expr { $w - $dx } ]
  set w2 [ action.clamp_w $w2 ]
  return [ list $x $y $w2 $h $a $b ]
}



proc action.sw { dx dy x y w h a b } {
  set w2 [ expr { $w - $dx } ]
  set w2 [ action.clamp_w $w2 ]
  set h2 [ expr { $h + $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w2 $h2 $a $b ]
}

proc action.s { dx dy x y w h a b } {
  set h2 [ expr { $h + $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w $h2 $a $b ]
}

proc action.se { dx dy x y w h a b } {
  set w2 [ expr { $w + $dx } ]
  set w2 [ action.clamp_w $w2 ]
  set h2 [ expr { $h + $dy } ]
  set h2 [ action.clamp_h $h2 ]
  return [ list $x $y $w2 $h2 $a $b ]
}

proc action.w { dx dy x y w h a b } {
  set w2 [ expr { $w + $dx } ]
  set w2 [ action.clamp_w $w2 ]
  return [ list $x $y $w2 $h $a $b ]
}


}
