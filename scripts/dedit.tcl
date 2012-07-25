


namespace eval mwc {

variable db <bad-db>
variable canvas_state <bad-canvas_state>
variable drag_last <bad-drag_last>
variable drag_item <bad-drag_item>
variable drag_handle <bad-drag_handle>
variable start_x 0
variable start_y 0
variable old_x_snap 0
variable old_y_snap 0

variable zooms { 20 40 50 60 70 75 80 85 90 95 100 105 110 120 130 140 150 160 180 200 250 300 400 500 }

# View: current diagram, scroll and zoom
variable zoom 100
variable scroll_x 0
variable scroll_y 0
variable g_current_dia ""

variable closed 0

proc get_db { } {
	variable db
	return $db
}

proc change_zoom_up { canvas_width canvas_height } {
	variable zoom
	set new_zoom [ zoomup $zoom ]
	change_zoom_to $canvas_width $canvas_height $new_zoom
}

proc change_zoom_down { canvas_width canvas_height } {
	variable zoom
	set new_zoom [ zoomdown $zoom ]
	change_zoom_to $canvas_width $canvas_height $new_zoom
}

proc find_scroll { screen old_scroll old_zoom new_zoom } {
	set model [ expr { $screen / $old_zoom * 100.0 + $old_scroll } ]
	set scroll [ expr { $model - $screen / $new_zoom * 100.0 } ]
	return $scroll
}

proc change_zoom_to { canvas_width canvas_height new_zoom } {
	variable zoom
	variable db
	variable scroll_x
	variable scroll_y

	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set old_zoom $zoom
	set zoom $new_zoom
	set screenx [ expr { double($mw::mouse_x0) } ]
	set screeny [ expr { double($mw::mouse_y0) } ]

	set scroll_x [ find_scroll $screenx $scroll_x $old_zoom $zoom ]
	set scroll_y [ find_scroll $screeny $scroll_y $old_zoom $zoom ]

	mv::fill $diagram_id
}

proc zoom_vertices { vertices } {
	return [ map -list $vertices -fun mwc::zoom_value ]
}

proc zoom_value { value } {
	variable zoom
	return [ expr { int($zoom / 100.0 * $value ) } ]
}

proc unzoom_value { value } {
	variable zoom
	return [ expr { int($value * 100.0 / $zoom) } ]
}


proc zoomup { old } {
	variable zooms
	set oldi [ expr { int($old) } ]
	set length [ llength $zooms ]
	for { set i 0 } { $i < $length } { incr i } {
		set next_i [ expr { $i + 1 } ]
		set value [ lindex $zooms $i ]
		if { $next_i == $length || $value > $oldi } {
			return $value
		}
	}
}

proc zoomdown { old } {
	variable zooms
	set oldi [ expr { int($old) } ]
	set length [ llength $zooms ]
	for { set i [ expr { $length - 1 } ] } { $i >= 0 } { incr i -1 } {
		set value [ lindex $zooms $i ]
		if { $i == 0 || $value < $oldi } {
			return $value
		}
	}
}

proc remember_old_pos { x y } {
	variable start_x
	variable start_y
	variable old_x_snap
	variable old_y_snap

	set start_x $x
	set start_y $y
	
	set old_x_snap 0
	set old_y_snap 0
}

proc snap_dx { x } {
	variable old_x_snap
	variable start_x
	
	set full_dx [ expr { $x - $start_x } ]
	set dx_snap [ snap_delta $full_dx ]
	set dx [ expr { $dx_snap - $old_x_snap } ]
	set old_x_snap $dx_snap
	return $dx
}

proc snap_dy { y } {
	variable old_y_snap
	variable start_y
	
	set full_dy [ expr { $y - $start_y } ]
	set dy_snap [ snap_delta $full_dy ]
	set dy [ expr { $dy_snap - $old_y_snap } ]
	set old_y_snap $dy_snap
	return $dy
}

proc init { dbname } {
	variable db
	set db $dbname
	state reset
	back::init
}

proc hover { cx cy shift } {
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]	
	
	insp::remember $cx $cy
	
	set item_below [ mv::hit $cx $cy ]
	if { $item_below == "" } {
		set cursor normal 
	} elseif { $shift } {
		set cursor item
	} else {
		set drag_handle [ mv::hit_handle $item_below $cx $cy ]
		if { $drag_handle == "" } {
			set cursor item
		} else {
			set cursor handle
		}    
	}

	mw::update_cursor $cursor
}

proc delete { ignored } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }

	set count [ $db onecolumn { select count(*) from items
		where diagram_id = :diagram_id and selected = 1 } ]
		
	if { $count == 0 } { return }
	
	begin_transaction delete

	start_action  "Delete"

	push_delete_items $diagram_id
	
	commit_transaction delete
}

proc double_click { cx cy } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	set item_id [ mv::hit $cx $cy ]
	if { $item_id == "" } { return }
	
	if { ![ mv::has_text $item_id ] } { return }
	set type [ mod::one $db type items item_id $item_id ]
	if { $type == "address" } { return }
	
	set old_text [ mod::one $db text items item_id $item_id ]

	set user_data [ list $item_id $old_text ]
	ui::text_window "Change icon text: item $item_id" $old_text mwc::do_change_text $user_data
}

proc file_description { } {
	variable db

	set old [ $db onecolumn { select description from state where row = 1 } ]
	ui::text_window "Edit file description" $old mwc::do_file_description $old
}

proc add_text_change { action rollback change_info table key field } {
	variable db
	upvar 1 $action do
	upvar 1 $rollback undo

	unpack $change_info id text
	set text [ sql_escape $text ]
	set old_text [ mod::one $db $field $table $key $id ]
	set old_text [ sql_escape $old_text ]
	
	lappend do [ list update $table $key $id $field '$text' ]
	lappend undo [ list update $table $key $id $field '$old_text' ]
}

proc adjust_icon_sizes { } {
	variable db

	begin_transaction adjust_icon_sizes
	save_view
	start_action  "Adjust icon sizes"

	set diagrams [ $db eval {
		select diagram_id from diagrams
	} ]

	set do_gui [ wrap mwc::refill_current foo ]
	set undo_gui $do_gui

	com::push $db $do_gui {} $undo_gui {}

	foreach diagram_id $diagrams {
		adjust_icons_in_dia $diagram_id
	}

	com::push $db $do_gui {} $undo_gui {}

	commit_transaction adjust_icon_sizes
}

proc adjust_icons_in_dia { diagram_id } {
	variable db
	
	set icons_to_adjust [ $db eval {
		select item_id
		from items
		where type not in ('vertical', 'horizontal', 'arrow', 'loopend') 
			and diagram_id = :diagram_id
	} ]

	set verticals [ $db eval {
		select item_id
		from items
		where type = 'vertical'
			and diagram_id = :diagram_id
	} ]
		
	set actions [ $db eval {
		select item_id
		from items
		where type in ('action', 'insertion')
			and diagram_id = :diagram_id
	} ]
	
	array set items {}
	
	foreach item_id $icons_to_adjust {
		set coords [ fit_for_text $item_id ]
		set items($item_id) $coords
	}
	
	set actions_on_v {}
	
	foreach item_id $actions {
		if { [ on_any_vertical $item_id $verticals ] } {
			lappend actions_on_v $item_id
		}
	}
	
	foreach item1 $actions_on_v {
		foreach item2 $actions_on_v {
			if { $item1 != $item2 && [ on_same_vertical $item1 $item2 items ] } {
				expand_if_other_wider $item1 $item2 items
			}
		}
	}
	
	foreach item_id $icons_to_adjust {
		unpack $items($item_id) old new
		push_changed_coords $item_id $old $new
	}
}

proc on_same_vertical { item1 item2 items_array } {
	upvar 1 $items_array items
	set new1 [ lindex $items($item1) 1 ]
	set new2 [ lindex $items($item2) 1 ]
	set x1 [ lindex $new1 0 ]
	set x2 [ lindex $new2 0 ]
	return [ expr { $x1 == $x2 } ]
}

proc expand_if_other_wider { this other items_array } {
	upvar 1 $items_array items

	set old1 [ lindex $items($this) 0 ]
	set new1 [ lindex $items($this) 1 ]
	set new2 [ lindex $items($other) 1 ]
	set w1 [ lindex $new1 2 ]
	set w2 [ lindex $new2 2 ]
	if { $w2 > $w1 } {
		set new1_changed [ lreplace $new1 2 2 $w2 ]
		set coords_changed [ list $old1 $new1_changed ]
		set items($this) $coords_changed
	}
}


proc on_any_vertical { item_id verticals } {
	foreach vertical_id $verticals {
		if { [ item_on_vertical $item_id $vertical_id ] } {
			return 1
		}
	}
	return 0
}

proc item_on_vertical { item_id vertical_id } {
	variable db
	unpack [ $db eval { select x, y, h from items where item_id = :item_id } ] xi yi hi
	unpack [ $db eval { select x, y, h from items where item_id = :vertical_id } ] x y h
	if { $xi == $x } {
		set top [ expr { $yi - $hi } ]
		set bottom [ expr { $yi + $hi } ]
		set line_bottom [ expr { $y + $h } ]
		return [ expr { $y <= $bottom && $line_bottom >= $top } ]
	} else {
		return 0
	}
}

proc global_replace { file diagrams icons } {
	variable db

	begin_transaction global_replace
	start_action  "Replace all"
	set action {}
	set rollback {}
	
	foreach icon $icons {
		add_text_change action rollback $icon items item_id text
	}

	foreach diagram $diagrams {
		add_text_change action rollback $diagram diagrams diagram_id description
	}
	
	foreach file_descr $file {
		unpack $file_descr foo description
		set change [ list 1 $description ]
		add_text_change action rollback $change state row description
	}

	set do {}
	set current_diagram_id [ editor_state $db current_dia ]
	if { $current_diagram_id != "" } {
		lappend do [ list mw::select_dia $current_diagram_id ]
	}

	com::push $db $do $action $do $rollback

	commit_transaction global_replace
}

proc do_file_description { ignored new_text } {
	variable db
	
	set old_text [ $db onecolumn { select description from state where row = 1 } ]
	if { $old_text == $new_text } { return 1 }
	
	set new_text_esc [ sql_escape $new_text ]
	set old_text_esc [ sql_escape $old_text ]
		
	set change [ wrap update state row 1 description '$new_text_esc' ]
	set change_back [ wrap update state row 1 description '$old_text_esc' ]

	set do {}
	set undo {}
	
	begin_transaction do_file_description
	start_action  "Change file description"
	
	com::push $db $do $change $undo $change_back
	
	commit_transaction do_file_description
	state reset
	
	return 1
}


proc change_text { item_id } {
	variable db

	set old_text [ mod::one $db text items item_id $item_id ]
	set user_data [ list $item_id $old_text ]
	ui::text_window "Change icon text: item $item_id" $old_text mwc::do_change_text $user_data
}

proc is_header { item_id } {
	variable db
	
	set row [ $db eval { select item_id, diagram_id, type, x, y from items where item_id = :item_id } ]
	unpack $row item_id diagram_id type x y
	if { $type != "beginend" } {
		return 0
	}
	
	set to_nw [ $db onecolumn { select count(*) from items
		where diagram_id = :diagram_id
		and item_id != :item_id
		and type != 'vertical'
		and type != 'horizontal'
		and type != 'arrow'
		and (x < :x or y < :y ) } ]
		
	if { $to_nw == 0 } {
		return 1
	}
	
	return 0
}

proc find_header { diagram_id } {
	variable db
	$db eval { select item_id from items where diagram_id = :diagram_id and type = 'beginend' } {
		if { [ is_header $item_id ] } {
			return $item_id
		}
	}
	return ""
}

proc p.fit { text type oldx oldy oldw oldh olda oldb} {
	set text_size [ mw::measure_text $text ]
	unpack $text_size tw th
	set tw [ expr { $tw / 2 } ]
	set th [ expr { $th / 2 } ]
	set tw [ snap_up $tw ]
	set th [ snap_up $th ]
	incr tw 10
	incr th 10
	set new_fields [ mv::$type.fit $tw $th $oldx $oldy $oldw $oldh $olda $oldb ]
	return $new_fields
}

proc push_fit_text { item_id } {
	variable db

	set old_fields [ $db eval { select text, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	unpack $old_fields old_text type oldx oldy oldw oldh olda oldb


	set new_fields [ p.fit $old_text $type $oldx $oldy $oldw $oldh $olda $oldb ]
	unpack $new_fields x y w h a b
		
	set change [ wrap update items item_id $item_id \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

	com::push $db {} $change {} $change_back
}

proc push_changed_coords { item_id old new } {
	variable db
	unpack $old oldx oldy oldw oldh olda oldb
	unpack $new x y w h a b
	set change [ wrap update items item_id $item_id \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

	com::push $db {} $change {} $change_back	
}

proc fit_for_text { item_id } {
	variable db

	set old_fields [ $db eval { select text, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	unpack $old_fields old_text type oldx oldy oldw oldh olda oldb


	set new_fields [ p.fit $old_text $type $oldx $oldy $oldw $oldh $olda $oldb ]

	
	set old [ list $oldx $oldy $oldw $oldh $olda $oldb ]

	return [ list $old $new_fields ]		
}


proc push_change_text { item_id new_text } {
	variable db

	set old_fields [ $db eval { select text, type, x, y, w, h, a, b
		from items where item_id = :item_id } ]
	unpack $old_fields old_text type oldx oldy oldw oldh olda oldb

	set new_text_esc [ sql_escape $new_text ]
	set old_text_esc [ sql_escape $old_text ]

	set new_fields [ p.fit $new_text $type $oldx $oldy $oldw $oldh $olda $oldb ]
	unpack $new_fields x y w h a b
		
	set change [ wrap update items item_id $item_id text '$new_text_esc' \
		x $x y $y w $w h $h a $a b $b ]
	set change_back [ wrap update items item_id $item_id text '$old_text_esc' \
		x $oldx y $oldy w $oldw h $oldh a $olda b $oldb ]

		
	set do [ wrap mv::redraw $item_id ]
	set undo $do
	
	com::push $db $do $change $undo $change_back
}

proc change_icon_text2 { data } {
	unpack $data item_id new_text
	change_icon_text $item_id $new_text
}

proc change_icon_text { item_id new_text } {
	variable db
	
	begin_transaction change_icon_text
	start_action  "Change text"

	push_change_text $item_id $new_text
	
	commit_transaction change_icon_text
	state reset
	return 1
}

proc do_change_text { old_data new_text } {
	variable db
	set item_id [ lindex $old_data  0 ]
	
	begin_transaction do_change_text
	start_action  "Change text"
	
	
	
	if { [ is_header $item_id ] } {
		set diagram_id [ editor_state $db current_dia ]
		if { $diagram_id != "" } {
			set dia_name [ string map { "'" "" } $new_text ]
			if { [ $db onecolumn { select count(*)
				from diagrams where name = :dia_name } ] == 0 } {
				push_rename_dia $diagram_id $dia_name
			}
		}
	}
	
	if { [ p.is_branch $item_id ] } {
		set addresses [ p.find_pointing_to $item_id ]
		foreach address $addresses {
			push_change_text $address $new_text
		}
	}

	push_change_text $item_id $new_text
	
	commit_transaction do_change_text
	state reset
	return 1
}

proc p.is_branch { item_id } {
	variable db
	set type [ $db onecolumn {
		select type
		from items
		where item_id = :item_id } ]
	return [ expr { $type == "branch" } ]
}

proc p.find_pointing_to { item_id } {
	variable db
	unpack [ $db eval {
		select text, diagram_id
		from items
		where item_id = :item_id } ] text diagram_id
	return [ $db eval {
		select item_id
		from items
		where diagram_id = :diagram_id
			and text = :text
			and type = 'address' } ]
}

proc ldown { move_data ctrl shift } {
	variable db
	variable drag_last
	variable drag_item
	variable drag_handle
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } {
		state reset
		return
	}
	
	mv::clear_changed
	
	set cx [ lindex $move_data 2 ]
	set cy [ lindex $move_data 3 ]
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	remember_old_pos $cx $cy
	set drag_last [ list $cx $cy ]
	set drag_item [ mv::hit $cx $cy ]
	if { $drag_item == "" } {
		if { !$ctrl } {
			mv::deselect_all
		}
		state change selecting.start
	} elseif { $shift } {
		set drag_items [ mv::hit_many $cx $cy ]
		state change alt_drag.start
		alt::start $drag_items $cx $cy
	} else {
		state change dragging.start
		set selected [ mod::one $db selected items item_id $drag_item ]
		if { $selected == 1 } {
			if { $ctrl } {
				mv::deselect $drag_item 0
			} else {
				set drag_handle [ mv::hit_handle $drag_item $cx $cy ]
				if { $drag_handle != "" } {
					state change resizing.start
					mv::prepare_line_handle $drag_item $drag_handle
				}
			}
		} else {
			if { !$ctrl } {
				mv::deselect_all
			}
			mv::select $drag_item 0
		}		 
	} 
}

proc lmove { move_data } {
	variable db
	variable drag_last
	variable drag_item
	variable drag_handle
	
	set cx [ lindex $move_data 2 ]
	set cy [ lindex $move_data 3 ]
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]	
	set dx [ lindex $move_data 4 ]
	set dy [ lindex $move_data 5 ]
	
	set item_below [ mv::hit $cx $cy ]
	set cursor normal
	
	set dx [ snap_dx $cx ]
	set dy [ snap_dy $cy ]
	
	if { [ state is selecting ] || [ state is selecting.start ] } {
		state change selecting
		mv::selection $drag_last [ list $cx $cy ]
	} elseif { [ state is dragging ] || [ state is dragging.start ] } {
		state change dragging
		mv::drag $dx $dy
		set cursor item
	} elseif { [ state is resizing ] || [ state is resizing.start ] } {
		state change resizing
		mv::resize $drag_item $drag_handle $dx $dy
		set cursor handle
	} elseif { [ state is alt_drag ] || [ state is alt_drag.start ] } {
		state change alt_drag
		set cursor item
		alt::mouse_move $dx $dy
	}
	
	mw::update_cursor $cursor
}

proc lup { move_data } {
	variable db
	variable drag_item
		
	begin_transaction lup
	set diagram_id [ editor_state $db current_dia ]
	
	mv::selection_hide
	
	if { [ state is selecting.start ] } {
		push_unselect_items $diagram_id
	} elseif { [ state is dragging.start ] || [ state is resizing.start ] } {
		take_selection_from_shadow $diagram_id
	} elseif { [ state is selecting ] } {		 
		take_selection_from_shadow $diagram_id
	} elseif { [ state is dragging ] } {
		take_selection_from_shadow $diagram_id
		start_action  "Move items"
		take_drag_from_shadow
	} elseif { [ state is resizing ] } {
		take_selection_from_shadow $diagram_id
		start_action  "Change shape"
		set changed [ mv::get_changed ]
		foreach changed_item $changed {
			take_resize_from_shadow $changed_item
		}
	} elseif { [ state is alt_drag ] } {
		start_action  "Move and change items"
		take_shapes_from_shadow [ mv::get_changed ]
	}
	
	commit_transaction lup
	state reset
}

proc rdown { cx cy } {
	variable db
	

	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]

	insp::remember $cx $cy

	set hit_item [ mv::hit $cx $cy ]
	if { $hit_item == "" } { return }
		
	set selected [ mod::one $db selected items item_id $hit_item ]
	if { !$selected } {
		begin_transaction rdown
		
		push_unselect_items $diagram_id
		push_select_item $hit_item
		
		
		commit_transaction rdown
	}
}

proc select_all { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }
	
	begin_transaction select_all
	
	push_unselect_items $diagram_id
	
	$db eval { select item_id from items where diagram_id = :diagram_id } {
		push_select_item $item_id
	}
	
	commit_transaction select_all
}

proc begin_transaction { procedure } {
	variable db
	log "begin transaction: $procedure"
	$db eval { begin transaction }
	udb eval { begin transaction }	
}

proc commit_transaction { procedure } {
	variable db
	global use_log
	log "commit transaction: $procedure"
	udb eval { commit transaction }
	$db eval { commit transaction }
	if { $use_log } {
		check_integrity
	}
}


proc do_create_item { name } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	if { ![ state is idle ] } { return }
	
	set constructor mv::$name.create
	
	begin_transaction do_create_item
	save_view
	
	set item_id [ mod::next_key $db items item_id ]

	set origin [ insp::current ]
	set origin [ snap_coords $origin ]
	unpack $origin x y
	
	set create_one [ $constructor $item_id $diagram_id $x $y ]
	#set text [ sql_escape [ lindex $create_one 9 ] ]
	set create_one [ lreplace $create_one 9 9 '' ]
	
	set w [ lindex $create_one 17 ]
	set h [ lindex $create_one 19 ]
	set a [ lindex $create_one 21 ]
	set b [ lindex $create_one 23 ]
	
	set new_fields [ p.fit "something" $name $x $y $w $h $a $b ]
	unpack $new_fields x y w h a b
	set create_one [ lreplace $create_one 17 17 $w ]
	set create_one [ lreplace $create_one 19 19 $h ]
	set create_one [ lreplace $create_one 21 21 $a ]
	set create_one [ lreplace $create_one 23 23 $b ]

	set create [ list $create_one ]
	set destroy [ wrap delete items item_id $item_id ]
	set do [ list [ list mv::insert $item_id ] [ list mv::select $item_id ] ]
	set undo [ list [ list mv::deselect $item_id ] [ list mv::delete $item_id ] ]

	
	start_action  "Insert '$name' icon"
	
	push_unselect_items $diagram_id
	com::push $db $do $create $undo $destroy
	
	commit_transaction do_create_item 
}


proc refill { diagram_id replay } {
	if { $replay } {
		fetch_view
		mv::fill $diagram_id
	}
}

proc refill_current { ignored replay } {
	fetch_view
	set diagram_id [ get_current_dia ]
	if { $diagram_id != "" } {
		fetch_view
		mv::fill $diagram_id
	}
}


proc scroll { x y } {
	variable scroll_x
	variable scroll_y

	
	set x2 [ unzoom_value $x ]
	set y2 [ unzoom_value $y ]
	set scroll_x $x2
	set scroll_y $y2

	#save_zoom
	state reset
}

proc editor_state { db key } {
	set sql "select $key from state"
	return [ $db onecolumn $sql ]
}

proc state.get_arg { action arguments } {
	if { [ llength $arguments ] == 0 } {
		error "state $action: target state required"
	}
	
	set new_state [ lindex $arguments 0 ] 
	
	set allowed { idle selecting dragging resizing selecting.start dragging.start resizing.start
		alt_drag alt_drag.start }
	if { [ lsearch -exact $allowed $new_state ] == -1 } {
		error "state $action: unknown state '$new_state'\nAvalable states: $allowed"
	}
	
	return $new_state
}

proc state { action args } {
	variable canvas_state
	
	switch $action {
		is {
			set new_state [ state.get_arg $action $args ]
			return [ expr { $new_state == $canvas_state } ]
		}
		reset { set canvas_state idle }
		change {
			set new_state [ state.get_arg $action $args ]			 
			set canvas_state $new_state
		}
		default { error "state: unsupported action '$action'" }
	}
}

proc get_scroll { } {
	return { 0 0 }
}

proc get_prim_count { } {
	variable db
	set id [ editor_state $db current_dia ]
	if { $id == "" } { return 0 }
	
	return [ $db onecolumn { select count(*) from items where diagram_id = :id } ]
}

proc get_current_dia { } {
	variable db
	if { $db == "<bad-db>" } { return "" }
	set id [ editor_state $db current_dia ]
	return $id
}

proc get_dia_name { diagram_id } {
  variable db
  if { $diagram_id == "" } { return "" }
  return [ $db onecolumn {
    select name
    from diagrams
    where diagram_id = :diagram_id } ]
}

proc get_dia_id { name } {
  variable db
  if { $name == "" } { return "" }
  return [ $db onecolumn {
    select diagram_id
    from diagrams
    where name = :name } ]
}

proc fill_tree_with_nodes { } {
	variable db
	mtree::clear
	
	$db eval {
		select node_id
		from tree_nodes
		where parent = 0
	} {
		add_tree_node $node_id
	}
}

proc add_tree_node { node_id } {
	variable db
	unpack [ $db eval {
		select type, name, diagram_id, parent
		from tree_nodes
		where node_id = :node_id } ] type name diagram_id parent
		
	if { $type == "item" } {
		set name [ $db onecolumn { select name from diagrams where diagram_id = :diagram_id } ]
	}
	
	mtree::add_item $parent $type $name $node_id
	
	$db eval {
		select node_id child
		from tree_nodes
		where parent = :node_id
	} {
		add_tree_node $child
	}
}

proc get_diagram_parameter { diagram_id name } {
	variable db
	return [ $db onecolumn {
		select value from diagram_info
		where diagram_id = :diagram_id
		and name = :name } ]
}

proc set_diagram_parameter { diagram_id name value } {
	variable db
	set count [ $db onecolumn { select count(*) from diagram_info
		where diagram_id = :diagram_id
		and name = :name } ]
	if { $count == 0 } {
		$db eval { insert into diagram_info (diagram_id, name, value)
			values (:diagram_id, :name, :value) }
	} else {
		$db eval { update diagram_info set value = :value
			where diagram_id = :diagram_id
			and name = :name }
	}
}


proc get_diagrams { } {
	variable db
	return [ $db eval { select name from diagrams order by name } ]
}

proc update_undo { } {
	variable db
	set current [ com::get_current_undo ]
	mw::disable_undo
	mw::disable_redo
	
	if { $current == "" } { return }
	
	set max [ $db onecolumn { select max(step_id) from undo_steps } ]
	if { $current > 0 } {
		set name [ mod::one $db name undo_steps step_id $current ]
		mw::enable_undo $name
	}
	
	set next [ expr { $current + 1 } ]
	if { $next <= $max } {
		set name [ mod::one $db name undo_steps step_id $next ]
		mw::enable_redo $name 
	}
}

proc build_new_diagram { id name sil parent_node node_id } {
	variable db
	
	set result {}
	lappend result [ list insert diagrams diagram_id $id name '$name' origin "'0 0'" zoom 100 ]
	lappend result [ list insert tree_nodes node_id $node_id parent $parent_node type 'item' diagram_id $id ]
	
	if { $sil } {
	  set result [ build_new_sil $id $name $result ]
	} else {
	  set item_id [ mod::next_key $db items item_id ]
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '$name' selected 0 x 170 y 60 w 100 h 20 a 60 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text 'End' selected 0 x 170 y 390 w 60 h 20 a 60 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' selected 0 x 170 y 80 w 0 h 290 a 0 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' selected 0 x 170 y 60 w 200 h 0 a 0 b 0 ]
	  incr item_id
	  lappend result [ list insert items item_id $item_id diagram_id $id type 'action' selected 0 x 370 y 60 w 60 h 30 a 0 b 0 ]	  
	  
	}
	return $result
}

proc build_new_sil { id name result } {
  variable db
  
  set item_id [ mod::next_key $db items item_id ]
  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text '$name' selected 0 x 170 y 60 w 100 h 20 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'beginend' text "'End'" selected 0 x 660 y 510 w 60 h 20 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 170 y 80 w 0 h 520 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 420 y 120 w 0 h 480 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'vertical' text "''" selected 0 x 660 y 120 w 0 h 380 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' text "''" selected 0 x 170 y 120 w 490 h 0 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'arrow' text "''" selected 0 x 20 y 120 w 150 h 480 a 400 b 1 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 1'" selected 0 x 170 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'address' text "'branch 2'" selected 0 x 170 y 550 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 2'" selected 0 x 420 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'branch' text "'branch 3'" selected 0 x 660 y 170 w 50 h 30 a 60 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'address' text "'branch 3'" selected 0 x 420 y 550 w 50 h 30 a 60 b 0 ]
  
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'horizontal' selected 0 x 170 y 60 w 200 h 0 a 0 b 0 ]
  incr item_id
  lappend result [ list insert items item_id $item_id diagram_id $id type 'action' selected 0 x 370 y 60 w 60 h 30 a 0 b 0 ]	  
  
  
  return $result
}


proc build_backup_item { item_id } {
	variable db
	$db eval {
		select
			item_id, diagram_id, type, text, selected, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} {
		set text [ sql_escape $text ]
		set insert_item [ list insert items \
			item_id				$item_id		\
			diagram_id		$diagram_id \
			type					'$type'			\
			text					'$text'			\
			selected				$selected		\
			x						$x					\
			y						$y					\
			w						$w				\
			h						$h					\
			a						$a					\
			b						$b					]
			
		return $insert_item
	}
}

proc build_backup_folder { node_id } {
	variable db
	$db eval {
		select parent, name
		from tree_nodes
		where node_id = :node_id
	} {
		return [ wrap insert tree_nodes node_id $node_id type 'folder' name '$name' parent $parent ]
	}
	error "Folder not found: $node_id"
}

proc build_backup_diagram { id } {
	variable db
	set fields [ mod::fetch $db diagrams diagram_id $id diagram_id name origin description zoom ]
	unpack $fields id name origin description zoom
	if { $zoom == "" } { set zoom 100 }
	set name [ sql_escape $name ]
	set description [ sql_escape $description ]
	
	set insert_diagram [ list insert diagrams diagram_id $id name '$name' origin '$origin' description '$description' zoom $zoom ]
	
	unpack [ mod::fetch $db tree_nodes diagram_id $id node_id parent ] node_id parent
	
	set insert_node [ list insert tree_nodes node_id $node_id parent $parent type 'item' diagram_id $id ]
	
	set result [ list $insert_diagram $insert_node ]
	
	$db eval { 
		select item_id
		from items
		where diagram_id = :id
	} {
		set insert_item [ build_backup_item $item_id ]
		lappend result $insert_item
	}
	
	$db eval {
		select name, value from diagram_info
		where diagram_id = :id
	} {
		set insert_info [ list insert diagram_info diagram_id $id name '$name' value '[ sql_escape $value ]' ]
		lappend result $insert_info
	} 
	
	return $result
}

proc build_delete_folder { node_id } {
	return [ wrap delete tree_nodes node_id $node_id ]
}

proc build_delete_diagram { id } {
	variable db
	
	set delete_node [ list delete tree_nodes diagram_id $id ]
	set delete_dia [ list delete diagrams diagram_id $id ]
	set delete_dia_info [ list delete diagram_info diagram_id $id ]
	set delete_items [ list delete items diagram_id $id ]
	set result [ list $delete_node $delete_dia $delete_dia_info $delete_items ]
 	
	return $result
}

proc check_diagram_name { name } {
	variable db
	if { [ string trim $name ] == "" } {
		return "Diagram name should not be empty"
	}
	if { [ string trim $name ] != $name } {
		return "Diagram name should not have trailing and leading spaces"
	}
	if { [ string first "'" $name ] != -1 } {
		return "Diagram name cannot contain single quotes"
	}		
	
	if { [ mod::exists $db diagrams name '$name' ] } {
		return "Diagram with name '$name' already exists."
	}
	return ""
}

proc check_folder_name { name } {
	variable db
	if { [ string trim $name ] == "" } {
		return "Folder name should not be empty"
	}
	if { [ string trim $name ] != $name } {
		return "Folder name should not have trailing and leading spaces"
	}
	if { [ string first "'" $name ] != -1 } {
		return "Folder name cannot contain single quotes"
	}		
	return ""
}


proc get_parent_node { sibling } {
	variable db
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 0 } {
		return 0
	}
	
	set selected [ lindex $selection 0 ]
	unpack [ $db eval {
		select type, parent from tree_nodes where node_id = :selected } ] type parent
	if { $type == "item" || $sibling } {
		set parent_node $parent
	} else {
		set parent_node $selected
	}
	return $parent_node
}

proc do_create_folder { parent_node new } {
	variable db
	set message [ check_folder_name $new ]
	if { $message != "" } {
		return $message
	}

	begin_transaction do_create_folder
	start_action  "Create folder" dont_save
	
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set old_current [ editor_state $db current_dia ]
	
	push_unselect $old_current
	
	set do_data [ wrap insert tree_nodes node_id $node_id type 'folder' name '$new' parent $parent_node ]
	set undo_data [ wrap delete tree_nodes node_id $node_id ]
	
	set do_gui [ wrap mwc::create_dia_node $node_id ]
	set undo_gui [ wrap mwc::delete_dia_node $node_id ]
	
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	commit_transaction do_create_folder
	state reset
	return ""
}


proc do_create_dia { new sil parent_node } {
	variable db
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return $message
	}
	
	begin_transaction do_create_dia
	
	start_action  "Create diagram" dont_save
	
	set id [ mod::next_key $db diagrams diagram_id ]
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set old_current [ editor_state $db current_dia ]
	
	push_unselect $old_current

	
	set insert [ build_new_diagram $id $new $sil $parent_node $node_id ]
	set delete [ build_delete_diagram $id ]
	
	set create_do [ wrap mwc::create_dia_node $node_id ]
	set create_undo [ wrap mwc::delete_dia_node $node_id ]
	
	com::push $db $create_do $insert $create_undo $delete
	
	push_select $id
	
	commit_transaction do_create_dia
	state reset
	
	return ""
}

proc take_selection_from_shadow { diagram_id } {
	variable db
	set new_selection [ mv::shadow_selection ]
	set old_selection [ $db eval { select item_id from items where diagram_id = :diagram_id and selected = 1 } ]
	set select {}
	set deselect { }
	set do { }
	set undo { }
	foreach old_selected $old_selection {
		lappend do [ list mv::deselect $old_selected ]
		lappend select [ list update items item_id $old_selected selected 0 ]
	}
	foreach new_selected $new_selection {
		lappend do [ list mv::select $new_selected ]
		lappend select [ list update items item_id $new_selected selected 1 ]
		lappend undo [ list mv::deselect $new_selected ]
		lappend deselect [ list update items item_id $new_selected selected 0 ]
	}
	foreach old_selected $old_selection {
		lappend undo [ list mv::select $old_selected ]
		lappend deselect [ list update items item_id $old_selected selected 1 ]
	}
	com::push $db $do $select $undo $deselect
}

proc take_drag_from_shadow { } {
	set selected [ mv::shadow_selection ]
	take_shapes_from_shadow $selected
}

proc take_resize_from_shadow { item_id } {
	set items [ list $item_id ]
	take_shapes_from_shadow $items
}

proc take_shapes_from_shadow { items } {
	variable db
	set drag {}
	set put_back {}
	set do {}
	set undo {}
	
	foreach item_id $items {	
		mb eval { select x, y, w, h, a, b from item_shadows where item_id = :item_id } {
			lappend drag [ list update items item_id $item_id x $x y $y w $w h $h a $a b $b ]
			set arg [ list $item_id $x $y $w $h $a $b ]
			lappend do [ list mv::move_to $arg ]
		}
		
		$db eval { select x, y, w, h, a, b from items where item_id = :item_id } {
			lappend put_back [ list update items item_id $item_id x $x y $y w $w h $h a $a b $b ]
			set arg [ list $item_id $x $y $w $h $a $b ]
			lappend undo [ list mv::move_to $arg ]
		}
	}
	if { [ llength $items ] > 0 } {
		com::push $db $do $drag $undo $put_back
	}
}

proc push_delete_items { diagram_id } {
	variable db
	
	set delete {}
	set undelete {}
	set do {}
	set undo {}

	
	$db eval { select item_id
					from items where diagram_id = :diagram_id
					and selected = 1 } {
		set insert_item [ build_backup_item $item_id ]
		set delete_item [ list delete items item_id $item_id ]
		set insert_cnv [ list mv::insert $item_id ]
		set delete_cnv [ list mv::delete $item_id ]

		
		lappend delete $delete_item
		lappend undelete $insert_item
		lappend do [ list mv::deselect $item_id ]
		lappend do $delete_cnv
		lappend undo $insert_cnv
		lappend undo [ list mv::select $item_id ]
	}
	
	if { [ llength $do ] > 0 } {
		com::push $db $do $delete $undo $undelete
	}	
}

proc push_unselect_items { diagram_id } {
	variable db
	
	set unselect {}
	set select {}

	set unselect_do {}
	set unselect_undo {}
	
	set counter 0
	
	$db eval { select item_id from items where diagram_id = :diagram_id and selected = 1 } {
		lappend unselect [ list update items item_id $item_id selected 0 ]
		lappend select [ list update items item_id $item_id selected 1 ]
		lappend unselect_do [ list mv::deselect $item_id ]
		lappend unselect_undo [ list mv::select $item_id ]
		incr counter
	}
	
	if { $counter > 0 } {
		com::push $db $unselect_do $unselect $unselect_undo $select
	}
}

proc push_select_item { item_id } {
	variable db
	
	set select [ wrap update items item_id $item_id selected 1 ]
	set deselect [ wrap update items item_id $item_id selected 0 ]
	set do [ wrap mv::select $item_id ]
	set undo [ wrap mv::deselect $item_id ]
	com::push $db $do $select $undo $deselect
}


proc fetch_zoom {  } {
	variable db
	variable zoom
	variable scroll_x
	variable scroll_y
	set diagram_id [ editor_state $db current_dia ]	
	if { $diagram_id == "" } { return }
	$db eval { select zoom z, origin from diagrams
		where diagram_id = :diagram_id } {

		if { $z == "" || int($z) == 0 } {
			set zoom 100
		} else {
			set zoom [ expr { int($z) } ]
		}
		unpack $origin scroll_x scroll_y
	}
}

proc save_zoom { } {
	variable db
	variable zoom
	variable scroll_x
	variable scroll_y
	set diagram_id [ editor_state $db current_dia ]	
	if { $diagram_id == "" } { return }
	set origin [ list $scroll_x $scroll_y ]
	$db eval { 
    update diagrams
    set zoom = :zoom, origin = :origin
		where diagram_id = :diagram_id }
}

proc fetch_view { } {
  variable g_current_dia
	variable db

	set g_current_dia [ editor_state $db current_dia ]	
	fetch_zoom
}

proc save_view { } {
  variable db
  variable g_current_dia
  $db eval {
    update state
    set current_dia = :g_current_dia }
    
  save_zoom
}

proc clear_g_current_dia { foo bar } {
	variable g_current_dia
	set g_current_dia ""
}

proc push_unselect { diagram_id } {
	variable db
	set clean_old [ wrap update state row 1 current_dia '' ]
	set unselect_do { { mw::unselect_dia_ex 1 } { mwc::clear_g_current_dia foo } }
	
	set restore_old {}
	set unselect_undo {}
	
	if { $diagram_id != "" } {
		lappend restore_old [ list update state row 1 current_dia $diagram_id ]	
		lappend unselect_undo [ list mw::select_dia $diagram_id ]
	}
	
	com::push $db $unselect_do $clean_old $unselect_undo $restore_old 
}

proc push_select { diagram_id } {

	variable db
	set set_new [ wrap update state row 1 current_dia $diagram_id ]
	set clean_new [ wrap update state row 1 current_dia '' ]

	set select_do {}
	lappend select_do [ list  mw::select_dia $diagram_id ]
		
	set select_undo [ wrap mw::unselect_dia_ex 1 ]
	com::push $db $select_do $set_new $select_undo $clean_new
}

proc new_dia_here { } {
	set parent_node [ get_parent_node 0 ]
	mwd::create_diagram_dialog mwc::do_create_dia $parent_node
}

proc new_dia { } {
	set parent_node [ get_parent_node 1 ]
	mwd::create_diagram_dialog mwc::do_create_dia $parent_node
}


proc undo { } {
	variable db
	begin_transaction undo
	com::undo $db
	commit_transaction undo
	state reset
}

proc redo { } {
	variable db
	begin_transaction redo
	com::redo $db
	commit_transaction redo
	state reset
}

proc get_node_info { node_id } {
	variable db
	return [ $db eval {
		select parent, type, name, diagram_id
		from tree_nodes
		where node_id = :node_id } ]
}

proc sort_selection { selection } {
	variable db
	set result {}
	
	$db eval {
		select node_id
		from tree_nodes
		where parent = 0
	} {
		set selected_in_subtree [ traverse_subtree $node_id $selection 0 ]
		set result [ concat $result $selected_in_subtree ]
	}
	
	return $result
}

proc traverse_subtree { node_id selection parent_selected } {
	variable db
	set result {}
	
	if { $parent_selected || [ contains $selection $node_id ] } {
		lappend result $node_id
		set parent_selected 1
	}
	
	$db eval {
		select node_id child
		from tree_nodes
		where parent = :node_id
	} {
		set in_child [ traverse_subtree $child $selection $parent_selected ]
		set result [ concat $result $in_child ]
	}
	
	return $result
}

proc get_diagram_node { diagram_id } {
	variable db
	return [ $db onecolumn {
		select node_id
		from tree_nodes
		where diagram_id = :diagram_id } ]
}

proc delete_tree_items { } {
	take_from_tree 1 0
}

proc do_delete_tree_items { sorted } {
	variable db
	
	
	begin_transaction delete_dia
	start_action  "Delete diagram"  dont_save	
	
	set old_current [ editor_state $db current_dia ]
	push_unselect $old_current	
	
	set delete_data {}
	set delete_gui {}
	set undelete_data {}
	set undelete_gui {}
	
	foreach node_id $sorted {
		unpack [ get_node_info $node_id ] parent type name diagram_id
		if { $type == "folder" } {
			set undo_data [ build_backup_folder $node_id ]		
		} else {
			set undo_data [ build_backup_diagram $diagram_id ]
		}
		lappend undelete_gui [ list mwc::create_dia_node $node_id ]
		set undelete_data [ concat $undelete_data $undo_data ]
	}
	
	set last [ expr { [ llength $sorted ] - 1 } ]
	for { set i $last } { $i >= 0 } { incr i -1 } {
		set node_id [ lindex $sorted $i ]
		unpack [ get_node_info $node_id ] parent type name diagram_id
		if { $type == "folder" } {
			set do_data [ build_delete_folder $node_id ]		
		} else {
			set do_data [ build_delete_diagram $diagram_id ]
		}
		lappend delete_gui [ list mwc::delete_dia_node $node_id ]
		set delete_data [ concat $delete_data $do_data ]
	}
		
	com::push $db $delete_gui $delete_data $undelete_gui $undelete_data

	commit_transaction delete_dia
	state reset
}

proc push_rename_dia { id new } {
	variable db
	
	set node_id [ get_diagram_node $id ]
	
	set old [ mod::one $db name diagrams diagram_id $id ]
	set rename [ wrap update diagrams diagram_id $id name '$new' ]
	set undo [ wrap update diagrams diagram_id $id name '$old' ]
	
	set rename_do [ wrap mwc::rename_dia_node $node_id ]
	set rename_undo [ wrap mwc::rename_dia_node $node_id ]
	com::push $db $rename_do $rename $rename_undo $undo
}

proc change_dia_name_only { id new } {
	variable db
	
	set old [ mod::one $db name diagrams diagram_id $id ]
	if { $old == $new } { return 0 }
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return 0
	}
	
	
	begin_transaction change_dia_name_only
	start_action  "Rename diagram"
	
	push_rename_dia $id $new

	commit_transaction change_dia_name_only
	state reset
	return 1
}

proc do_rename_folder { node_id new } {
	variable db
	set message [ check_folder_name $new ]
	if { $message != "" } {
		return $message
	}
	set old [ $db onecolumn {
		select name from tree_nodes where node_id = :node_id } ]
	if { $old == $new } { return "" }

	begin_transaction do_rename_folder
	start_action  "Rename folder"
	
	set do_data [ wrap update tree_nodes node_id $node_id name '$new' ]
	set undo_data [ wrap update tree_nodes node_id $node_id name '$old' ]
	set do_gui [ wrap mwc::rename_dia_node $node_id ]
	set undo_gui $do_gui
	
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	commit_transaction do_rename_folder
	state reset
	return ""
}

proc do_rename_dia { node_id new } {
	variable db
	set old [ $db onecolumn {
		select name from tree_nodes where node_id = :node_id } ]	
	if { $old == $new } { return "" }
	set message [ check_diagram_name $new ]
	if { $message != "" } {
		return $message
	}
	
	begin_transaction do_rename_dia
	start_action  "Rename diagram"
	
	set id [ mod::one $db diagram_id tree_nodes node_id $node_id ]
	push_rename_dia $id $new
	
	set header [ find_header $id ]
	if { $header != "" } {
		push_change_text $header $new
	}
	
	commit_transaction do_rename_dia
	state reset
	return ""
}

proc do_dia_properties { old new } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return "" }
	
	return [ do_dia_properties_kernel $diagram_id $new ]
}

proc do_dia_properties_kernel { diagram_id new } {
	variable db
	
	set old [ mod::one $db description diagrams diagram_id $diagram_id ]
	if { $old == $new } { return "" }
	
	
	begin_transaction do_dia_properties_kernel
	start_action  "Change diagram description"
	
	set old_e [ sql_escape $old ]
	set new_e [ sql_escape $new ]
	
	set change [ wrap update diagrams diagram_id $diagram_id description '$new_e' ]
	set revert [ wrap update diagrams diagram_id $diagram_id description '$old_e' ]
	set do [ wrap mw::update_description foo ]
	set undo [ wrap mw::update_description foo ]
	
	com::push $db $do $change $undo $revert
	
	commit_transaction do_dia_properties_kernel
	state reset

	return ""
}

proc rename_dia { } {
	variable db
	
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] != 1 } { return }
	
	set node_id [ lindex $selection 0 ]
	unpack [ get_node_info $node_id ] parent type foo diagram_id
	
	set old [ get_node_text $node_id ]
	if { $type == "folder" } {
		ui::input_box "Rename folder" $old mwc::do_rename_folder $node_id 
	} else {
		ui::input_box "Rename diagram" $old mwc::do_rename_dia $node_id 
	}
}

proc goto_item { } {
	variable db
	ui::input_box "Go to item" "" mwc::do_goto_item foo
}

proc do_goto_item { foo item } {
	variable db
	set trimmed [ string trim $item ]
	if { $trimmed == "" } {
		return "Please enter an item id."
	}

	if { ![ string is integer $trimmed ] } {
		return "Item id should be a whole number."
	}

	set count [ $db onecolumn {
		select count(*) from items where item_id = :trimmed } ]
	if { $count != 1 } {
		return "Item $trimmed not found"
	}
	switch_to_item $trimmed
	return ""
}

proc new_folder_here { } {

	set parent_node [ get_parent_node 0 ]
	ui::input_box "Create folder" "" mwc::do_create_folder $parent_node
}

proc new_folder { } {
	set parent_node [ get_parent_node 1 ]
	ui::input_box "Create folder" "" mwc::do_create_folder $parent_node
}


proc get_items_to_copy { diagram_id selected_only } {
	variable db
	
	set result {}
	$db eval { 
		select item_id, type, text, selected, x, y, w, h, a, b
		from items
		where diagram_id = :diagram_id
	} {
		if { $selected || !$selected_only } {			
			lappend result [ list $item_id $type $text $selected $x $y $w $h $a $b ]
		}
	}
	return $result
}

proc copy { ignored } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return 0 }

	set items_data [ get_items_to_copy $diagram_id 1 ]
	if { [ llength $items_data ] != 0 } {
		mw::put_items_to_clipboard $items_data
		return 1
	}
	return 0
}

proc cut { ignored } {
	if { [ copy foo ] } {
		delete foo
	}
}

proc get_sorted_nodes { } {
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 0 } { return {} }
	set sorted [ sort_selection $selection ]
	return $sorted
}

proc take_from_tree { delete copy } {
	set sorted [ get_sorted_nodes ]
	if { [ llength $sorted ] == 0 } { return }
	
	if { $copy } {
		do_copy_tree $sorted
	}
	
	if { $delete } {	
		do_delete_tree_items $sorted
	}
}

proc copy_tree { } {
	take_from_tree 0 1
}

proc cut_tree { } {
	take_from_tree 1 1
}

proc get_node_to_copy { node_id } {
	variable db
	$db eval {
		select parent, type, name, diagram_id
		from tree_nodes
		where node_id = :node_id
	} {
		return [ list $node_id $parent $type $name $diagram_id ]
	}
}

proc get_diagram_properties { diagram_id } {
	variable db 
	set result {}
	$db eval {
		select name, value
		from diagram_info
		where diagram_id = :diagram_id
	} {
		lappend result $name $value
	}
	return $result
}

proc get_diagram_to_copy { diagram_id } {
	variable db
	set items_data [ get_items_to_copy $diagram_id 0 ]
	set properties [ get_diagram_properties $diagram_id ]
	$db eval {
		select name, origin, description, zoom
		from diagrams
		where diagram_id = :diagram_id
	} {
		return [ list $diagram_id $name $origin $description $zoom $items_data $properties ]
	}
}

proc do_copy_tree { sorted } {
	set nodes {}
	set diagrams {}
	
	foreach node_id $sorted {
		lappend nodes [ get_node_to_copy $node_id ]
		
		unpack [ get_node_info $node_id ] parent type name diagram_id
		if { $type == "item" } {
			lappend diagrams [ get_diagram_to_copy $diagram_id ]
		}
	}
	
	set content [ list $diagrams $nodes ]
	mw::put_nodes_to_clipboard $content
}

proc make_diagram_ids { diagrams } {
	variable db
	set diagram_id [ mod::next_key $db diagrams diagram_id ]
	
	set result {}
	foreach diagram $diagrams {
		set old_diagram_id [ lindex $diagram 0 ]
		lappend result $old_diagram_id $diagram_id
		incr diagram_id
	}
	
	return $result
}

proc name_not_unique { name result } {
	variable db
	if { [ contains $result $name ] } { return 1 }
	if { [ $db onecolumn {
		select count(*) from diagrams where name = :name } ] > 0 } {
		return 1
	}
	return 0
}

proc make_diagram_names { diagrams } {
	variable db
	
	set result {}
	foreach diagram $diagrams {
		set old_diagram_name [ lindex $diagram 1 ]
		set name $old_diagram_name
		set i 2
		while { [ name_not_unique $name $result ] } {
			set name "$old_diagram_name-$i"
			incr i
		}
		
		lappend result $old_diagram_name $name
	}
	
	return $result	
}

proc make_node_ids { nodes } {
	variable db
	set node_id [ mod::next_key $db tree_nodes node_id ]
	
	set result {}
	foreach node $nodes {
		set old_node_id [ lindex $node 0 ]
		lappend result $old_node_id $node_id
		incr node_id
	}
	
	return $result	
}

proc make_item_ids { items first_item_id } {
	set item_id $first_item_id
	set result {}
	foreach item $items {
		set old_item_id [ lindex $item 0 ]
		lappend result $old_item_id $item_id
		incr item_id
	}
	return $result
}

proc make_item_ids_tree { diagrams } {
	variable db
	set item_id [ mod::next_key $db items item_id ]

	set result {}
	foreach diagram $diagrams {
		set items [ lindex $diagram 5 ]
		set ids [ make_item_ids $items $item_id ]
		set item_id [ expr { $item_id + [ llength $ids ] / 2 } ]
		set result [ concat $result $ids ]
	}
	
	return $result
}

proc make_paste_diagram_actions { diagram diagram_ids diagram_names item_ids } {
	array set ids $diagram_ids
	array set names $diagram_names
	array set it_ids $item_ids
	
	set do_data {}
	
	unpack $diagram old_diagram_id old_name origin description zoom items_data properties
	set name $names($old_name)
	set diagram_id $ids($old_diagram_id)
	set description [ sql_escape $description ]
	
	lappend do_data [ list insert diagrams diagram_id $diagram_id name '$name' origin '$origin' \
		description '$description' zoom $zoom ]
	
	
	unpack [ make_paste_items_actions $diagram_id $items_data $item_ids 0 0 ] \
		items_do_gui items_do_data items_undo_gui items_undo_data

	set do_data [ concat $do_data $items_do_data ]
	
	set prop_count [ expr { [ llength $properties ] / 2 } ]
	repeat i $prop_count {
		set key_index [ expr { $i * 2 } ]
		set value_index [ expr { $key_index + 1 } ]
		set pname [ lindex $properties $key_index ]
		set pvalue [ lindex $properties $value_index ]
		lappend do_data [ list insert diagram_info diagram_id $diagram_id name '$pname' value '$pvalue' ]
	}
	
	set undo_data [ list \
		[ list delete diagram_info diagram_id $diagram_id ] \
		[ list delete items diagram_id $diagram_id ] \
		[ list delete diagrams diagram_id $diagram_id ] ]
		
	return [ list $do_data $undo_data ]
}

proc make_paste_node_actions { node node_ids diagram_ids parent } {

	array set dias $diagram_ids
	array set ids $node_ids
	
	unpack $node old_node_id old_parent type name diagram_id
	
	if { $diagram_id != "" } {
		set diagram_id $dias($diagram_id)
	}
	
	set node_id $ids($old_node_id)
	
	if { [ info exists ids($old_parent) ] } {
		set parent_id $ids($old_parent)
	} else {
		set parent_id $parent
	}
	
	if { $diagram_id == "" } {
		set diagram_id null
	}
	set do_data [ list insert tree_nodes node_id $node_id parent $parent_id type '$type' name '$name' \
		diagram_id $diagram_id ]
	set undo_data [ list delete tree_nodes node_id $node_id ]
	
	set do_gui [ list mwc::create_dia_node $node_id ]
	set undo_gui [ list mwc::delete_dia_node $node_id ]
	return [ list $do_gui $do_data $undo_gui $undo_data ]
}

proc paste_tree_here { } {
	paste_tree_kernel 0
}

proc paste_tree { } {
	paste_tree_kernel 1
}

proc paste_tree_kernel { sibling } {
	variable db
	
	unpack [ mw::take_nodes_from_clipboard ] diagrams nodes
	
	set diagram_ids [ make_diagram_ids $diagrams ]
	set diagram_names [ make_diagram_names $diagrams ]
	set node_ids [ make_node_ids $nodes ]
	
	set item_ids [ make_item_ids_tree $diagrams ]

	set parent [ get_parent_node $sibling ]

	set diagram_actions {}
	set node_actions {}
	
	foreach diagram $diagrams {
		set actions [ make_paste_diagram_actions $diagram $diagram_ids $diagram_names $item_ids ]
		unpack $actions paste delete
		lappend diagram_actions $actions
	}
	
	foreach node $nodes {
		lappend node_actions [ make_paste_node_actions $node $node_ids $diagram_ids $parent ]
	}
	
	set do_data {}
	set undo_data {}
	set do_gui {}
	set undo_gui {}
	
	foreach actions $diagram_actions {
		unpack $actions paste delete
		set do_data [ concat $do_data $paste ]
	}
	
	foreach actions $node_actions {
		unpack $actions do paste undo delete
		lappend do_data $paste
		lappend do_gui $do
	}
	
	set last [ expr { [ llength $node_actions ] - 1 } ]
	for { set i $last } { $i >= 0 } { incr i -1 } {
		unpack [ lindex $node_actions $i ] do paste undo delete
		lappend undo_data $delete
		lappend undo_gui $undo
	}

	foreach actions $diagram_actions {
		unpack $actions paste delete
		set undo_data [ concat $undo_data $delete ]		
	}
	
	lappend undo_gui [ list mw::unselect_dia_ex 1 ]

	
	begin_transaction paste_tree
	
	start_action  "Paste nodes"
	
	set diagram_id [ editor_state $db current_dia ]
	push_unselect $diagram_id
		
	com::push $db $do_gui $do_data $undo_gui $undo_data
	
	set pasting_one_diagram [ expr { [ llength $diagrams ] == 1 && [ llength $nodes ] == 1 } ]
	if { $pasting_one_diagram } {
		set new_diagram_id [ lindex $diagram_ids 1 ]
		push_select $new_diagram_id
	}
	
	commit_transaction paste_tree
	state reset	
}


proc get_left_top { items_data } {
	set min_x ""
	set min_y ""
	foreach item_data $items_data {
		unpack $item_data foo type text selected x y w h a b	
		
		if { $type == "horizontal" || $type == "arrow" } {
			set left $x
		} else {
			set left [ expr { $x - $w } ]
		}
		
		if { $type == "vertical" || $type == "arrow" } {
			set top $y
		} else {
			set top [ expr { $y - $h } ]
		}
		
		if { $min_x == "" || $min_x > $left } {
			set min_x $left
		}
		
		if { $min_y == "" || $min_y > $top } {
			set min_y $top
		}
	}
	return [ list $min_x $min_y ]
}

proc calculate_shift { left_top } {
	unpack [ insp::current ] mx my
	set left [ lindex $left_top 0 ]
	set top [ lindex $left_top 1 ]
	set dx [ snap_delta [ expr { $mx - $left - 20 } ] ]
	set dy [ snap_delta [ expr { $my - $top - 20 } ] ]
	return [ list $dx $dy ]
}

proc swap_item { item_id } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	begin_transaction swap_item
	start_action  "Change item"

	set before [ mod::one $db b items item_id $item_id ]
	set after [ expr { !$before } ]

	
	set swap [ wrap update items item_id $item_id b $after ]
	set revert [ wrap update items item_id $item_id b $before ]
	
	set do [ list \
		[ list mv::delete $item_id ] \
		[ list mv::insert $item_id ] \
		[ list mv::select $item_id ] ]
		
	com::push $db $do $swap $do $revert 
	commit_transaction swap_item
	
	state reset		
}

proc make_paste_items_actions { diagram_id items_data item_ids dx dy } {
	set paste {}
	set delete {}
	set do {}
	set undo {}
	
	array set ids $item_ids

	
	foreach item_data $items_data {
		unpack $item_data old_item_id type text selected x y w h a b
		set text [ sql_escape $text ]
		set x [ snap_up [ expr { $x + $dx } ] ]
		set y [ snap_up [ expr { $y + $dy } ] ]
		
		set item_id $ids($old_item_id)
		
		lappend paste [ list insert items \
			item_id $item_id \
			diagram_id $diagram_id \
			type '$type' \
			text '$text' \
			selected $selected \
			x $x \
			y $y \
			w $w \
			h $h \
			a $a \
			b $b ]
			
		lappend delete [ list delete items item_id $item_id ]
		lappend do [ list mv::insert $item_id ]
		if { $selected } {
			lappend do [ list mv::select $item_id ]
		}
		lappend undo [ list mv::delete $item_id ]
	}
	
	return [ list $do $paste $undo $delete ]
}

proc paste { ignored } {
	variable db
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return }

	set items_data [ mw::take_items_from_clipboard ]
	if { [ llength $items_data ] == 0 } { return }
	
	set left_top [ get_left_top $items_data ]
	set shift [ calculate_shift $left_top ]
	set dx [ lindex $shift 0 ]
	set dy [ lindex $shift 1 ]
	

	set item_id [ mod::next_key $db items item_id ]

	set item_ids [ make_item_ids $items_data $item_id ]
	
	unpack [ make_paste_items_actions $diagram_id $items_data $item_ids $dx $dy ] do paste undo delete
	
	begin_transaction paste
	
	start_action  "Paste items"
	push_unselect_items $diagram_id
		
	com::push $db $do $paste $undo $delete 
	
	commit_transaction paste
	state reset	
}

proc get_context_commands { cx cy } {
	variable db
	set cx [ unzoom_value $cx ]
	set cy [ unzoom_value $cy ]
	
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return {} }
	
	set selected [ $db eval { select item_id from items 
		where selected = 1 and diagram_id = :diagram_id } ]
		
	if { [ llength $selected ] == 0 } {
		set copy_state disabled
	} else {
		set copy_state normal
	}
	
	if { [ mw::can_paste_items ] } {
		set paste_state normal
	} else {
		set paste_state disabled
	}
	
	set commands [ list \
		[ list command "Copy" $copy_state mwc::copy {} ] \
		[ list command "Cut" $copy_state mwc::cut {} ] \
		[ list command "Paste" $paste_state mwc::paste { } ] \
		[ list separator ] \
		[ list command "Delete" $copy_state mwc::delete { } ]	\
		[ list separator ] ]

	set hit_item [ mv::hit $cx $cy ]
	if { $hit_item != "" } {
		$db eval { select type, selected from items where item_id = :hit_item } {
			if { $selected } {
				if { [ mv::has_text $hit_item ] } {
					if { $type != "address" } {
						lappend commands [ list command "Edit text..." normal mwc::change_text $hit_item ]
					}
					set referenced [ find_referenced_diagrams $hit_item ]
					foreach dia $referenced {
						unpack $dia ref_id ref_name
						if { $ref_id != $diagram_id } {
							lappend commands [ list command "Go to '$ref_name'" normal mwc::switch_to_dia $ref_id ]
						}
					}
				}
				set switch_command [ mv::$type.switch ]
				if { $switch_command != "" } {
					lappend commands [ list command $switch_command normal mwc::swap_item $hit_item ]
				}
				if { [ p.is_address $hit_item ] } {
					set branches [ p.get_branches_except $hit_item ]
					foreach branch $branches {
						lappend commands [ list command "Point to '$branch'" normal mwc::change_icon_text2 \
							[ list $hit_item $branch ] ]
					}
				}
			}
		}
	}
	return $commands
}

proc p.is_address { hit_item } {
	variable db
	set type [ mod::one $db type items item_id $hit_item ]
	return [ expr { $type == "address" } ]
}

proc p.get_branches_except { hit_item } {
	variable db
	set text [ mod::one $db text items item_id $hit_item ]
	set diagram_id [ mod::one $db diagram_id items item_id $hit_item ]	
	return [ $db eval {
		select text
		from items
		where diagram_id = :diagram_id
			and text != :text
			and type = 'branch' 
		order by x } ]
}


proc change_current_dia { old_id new_id hard record } {
	variable db
	
	if { $new_id == $old_id } { return }

	begin_transaction change_current_dia
	save_view
	
	if { $old_id != "" } {
		mw::unselect_dia "" 0
	}
	
	$db eval {
    update state 
    set current_dia = :new_id }
  
	fetch_view
	
	if { $new_id != "" } {
		mw::select_dia_kernel $new_id $hard
		if { $record } {
			back::record $new_id
		}
	}
	
	commit_transaction change_current_dia
	state reset
}

proc get_selected_from_tree { } {
	variable db
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] != 1 } { return "" }
	set selected_node [ lindex $selection 0 ]
	unpack [ $db eval {
		select type, diagram_id from tree_nodes where node_id = :selected_node } ] type diagram_id
	if { $type == "folder" } {
		return ""
	} elseif { $type == "item" } {
		if { $diagram_id == "" } {
			error "Empty diagram id for node $selected_node"
		}
		return $diagram_id
	} else {
		error "Bad node type: $type (selected_node=$selected_node, diagram_id=$diagram_id, selection=$selection)"
	}
}

proc current_dia_changed {} {
	variable db

	
	
	set old_id [ editor_state $db current_dia ]
	set new_id [ get_selected_from_tree ]
	

	if { $new_id == "" && $old_id == "" } { return }
	
	change_current_dia $old_id $new_id 1 1
}



proc switch_to_dia { diagram_id } {
	variable db
	
	if { $diagram_id == "" } { return }
	set old_id [ editor_state $db current_dia ]
	change_current_dia $old_id $diagram_id 0 1
}

proc switch_to_dia_no_hist { diagram_id } {
	variable db
	set old_id [ editor_state $db current_dia ]
	change_current_dia $old_id $diagram_id 0 0
}

proc diagram_exists { diagram_id } {
	variable db
	set count [ $db onecolumn { 
		select count(*) from diagrams where diagram_id = :diagram_id
	} ]
	return [ expr { $count > 0 } ]
}

proc center_on { item_id } {
	variable db
	variable scroll_x
	variable scroll_y
	
	set width [ unzoom_value $mw::canvas_width ]
	set height [ unzoom_value $mw::canvas_height ]
	$db eval {
		select x, y
		from items
		where item_id = :item_id
	} {
		set width2 [ expr { $width / 2 } ]
		set height2 [ expr { $height / 2 } ]
		set scroll_x [ expr { $x - $width2 } ]
		set scroll_y [ expr { $y - $height2 } ]
		set cscroll_x [ zoom_value $scroll_x ]
		set cscroll_y [ zoom_value $scroll_y ]
		set cscroll [ list $cscroll_x $cscroll_y ]
		mw::scroll $cscroll 1
	}
}

proc switch_to_item { item_id } {
	variable db
	set new_diagram_id [ mod::one $db diagram_id items item_id $item_id ]


	switch_to_dia $new_diagram_id
	
	begin_transaction switch_to_item

	push_unselect_items $new_diagram_id
	push_select_item $item_id
	center_on $item_id

	save_view
	commit_transaction switch_to_item
	state reset	
}

proc get_dia_description { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return "" }
	return [ mod::one $db description diagrams diagram_id $diagram_id ]
}

proc has_selection { } {
	variable db
	set diagram_id [ editor_state $db current_dia ]
	if { $diagram_id == "" } { return 0 }
	
	set count [ $db onecolumn { select count(*) from items where diagram_id = :diagram_id
		and selected = 1 } ]
	
	if { $count == 0 } { return 0 }
	return 1
}

proc dia_properties { } {
	variable db
	set id [ editor_state $db current_dia ]
	if { $id == "" } { return }

	set descr_name [ $db eval { select description, name from diagrams where diagram_id = :id } ]
	unpack $descr_name old dia_name

	ui::text_window "$dia_name: Edit diagram description" $old mwc::do_dia_properties $old
}



proc create_file { } {
	variable db
	log create_file
	set filename [ ds::requestspath .drn ]
	if { $filename != "" } {
		mod::close $db
		if { ![ ds::createfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc open_file { } {
	variable db
	set filename [ ds::requestopath ]
	if { $filename != "" } {
		mod::close $db
		if { ![ ds::openfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc save_as { } {
	set filename [ ds::requestspath .drn ]
	if { $filename != "" } {
		if { ![ ds::saveasfile $filename ] } { 
			ds::complain_file $filename
			exit
		}
	}
}

proc prime_view { diagram_id sx sy zoom_level } {
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  
}

proc set_view { view } {
  variable db
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  set old_zoom $zoom
  set old_dia $g_current_dia
  
  unpack $view g_current_dia scroll_x scroll_y zoom
  $db eval { update state set current_dia = :g_current_dia }
  
  if { $g_current_dia != "" } {
    set origin [ list $scroll_x $scroll_y ]
    $db eval {
      update diagrams
      set zoom = :zoom, origin = :origin
      where diagram_id = :g_current_dia }
  }

  if { $g_current_dia != $old_dia || $zoom != $old_zoom } {
    if { $g_current_dia != "" } {
      mw::unselect_dia "" 1
      mw::select_dia $g_current_dia 1
    }
  } else {
    set cx [ zoom_value $scroll_x ]
    set cy [ zoom_value $scroll_y ]
    mw::scroll [ list $cx $cy ] 1
  }  
}

proc start_action { name { save_camera save } } {
  variable zoom
  variable scroll_x
  variable scroll_y
  variable g_current_dia

  
  
  if { $save_camera == "dont_save" } {
    set delegates {}
  } elseif { $save_camera == "save" } {
    save_view
    set view [ list $g_current_dia $scroll_x $scroll_y $zoom ]
    set delegates [ wrap mwc::set_view $view ]
  } else {
    error "Wrong value of 'save_camera': $save_camera"
  }
  
  com::start_action $name $delegates
}


proc check_integrity { } {
	variable db
	set errors {}
	$db eval {
		select node_id, parent
		from tree_nodes
		where parent != 0
	} {
		set found [ $db onecolumn {
			select count(*) from tree_nodes where node_id = :parent } ]
		if { $found == 0 } {
			lappend errors "Node $node_id [ get_node_text $node_id ] has a dangling parent id: $parent."
		}
	}
	
	if { [ llength $errors ] != 0 } {
		error $errors
	}
}

proc goto {} {
	variable db
	set diagrams {}
	
	$db eval {
		select diagram_id, name
		from diagrams
	} {
		lappend diagrams $name $diagram_id
	}
	
	jumpto::goto_dialog $diagrams
}


proc find_referenced_diagrams { item_id } {
	variable db
	set text [ $db onecolumn {
		select text
		from items
		where item_id = :item_id } ]
	set result {}
	$db eval {
		select diagram_id, name
		from diagrams
		order by name
	} {
		if { [ string first $name $text ] != -1 } {
			lappend result [ list $diagram_id $name ]
		}
	}
	return [lrange $result 0 5 ]
}

proc property_keys { } {
	return { language canvas_font canvas_font_size pdf_font pdf_font_size }
}

proc get_file_properties { } {
	variable db
	set result {}
	set keys [ property_keys ]
	$db eval {
		select key, value
		from info
	} {
		if { [ contains $keys $key ] } {
			lappend result $key $value
		}
	}
	return $result
}

proc set_file_properties { props } {
	variable db
	array set properties $props
	set keys [ property_keys ]

	set do {}
	set undo {}

	# deletes
	foreach key $keys {
		set value [ $db onecolumn { select value from info where key = :key } ]
		set value [ sql_escape $value ]
		if { $value != "" && ![ info exists properties($key) ] } {
			lappend do [ list delete info key '$key' ]
			lappend undo [ list insert info key '$key' value '$value' ]
		}
	}

	foreach key [ array names properties ] {
		set old_value [ $db onecolumn { select value from info where key = :key } ]
		set new_value [ sql_escape $properties($key) ]
		if { $old_value == "" } {
			# insert
			lappend do [ list insert info key '$key' value '$new_value' ]
			lappend undo [ list delete info key '$key' ]
		} else {
			# update
			set old_value [ sql_escape $old_value ]
			lappend do [ list update info key '$key' value '$new_value' ]
			lappend undo [ list update info key '$key' value '$old_value' ]
		}
	}
	
	begin_transaction set_file_properties
	start_action  "Change file properties"
	
	set action [ wrap mwc::refill_all foo ]
	com::push $db $action $do $action $undo
	
	commit_transaction set_file_properties
	state reset
	
	return 1
}

proc refill_all { foo replay } {
	mwf::reset
	refill_current foo 1
}

}
