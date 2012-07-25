namespace eval graph {

proc copy_from { db } {
	p.create_db
	$db eval {
		select item_id, diagram_id, type, text, x, y, w, h, a, b
		from items
	} {
		gdb eval {
			insert into items(item_id, diagram_id, type, text, x, y, w, h, a, b)
			values (:item_id, :diagram_id, :type, :text, :x, :y, :w, :h, :a, :b)
		}
	}
	
	$db eval {
		select diagram_id, name
		from diagrams
	} {
		gdb eval {
			insert into diagrams (diagram_id, name)
			values (:diagram_id, :name)
		}
	}
}

proc p.create_db { } {
	catch { gdb close }
	sqlite3 gdb :memory:
	gdb eval {
		create table diagrams
		(
			diagram_id integer primary key,
			name text
		);
		
		create table items
		(	
			item_id integer primary key,
			diagram_id integer,
			type text,
			text text,
			x integer,
			y integer,
			w integer,
			h integer,
			a integer,
			b integer
		);
		
		create index items_by_diagram on items(diagram_id);
		
		create table vertices
		(
			vertex_id integer primary key,
			diagram_id integer,
			x integer,
			y integer,
			w integer,
			h integer,
			a integer,
			b integer,
			item_id integer,
			up integer,
			left integer,
			right integer,
			down integer,
			marked integer,
			type text,
			text text,
			parent integer
		);
		
		create unique index vertex_by_coord on vertices(diagram_id, x, y);
		
		create table edges
		(
			edge_id integer primary key,
			diagram_id integer,
			point1 text,
			point2 text,
			vertex1 integer,
			vertex2 integer,
			head integer,
			vertical integer,
			items text,
			marked integer
		);
		
		create index edges_by_diagram on edges(diagram_id);
		
		create table errors
		(
			error_id integer primary key,
			diagram_id integer,
			items text,
			message text
		);
		
		create unique index uerror on errors(diagram_id, items, message);
		
		create table results
		(
			result_id integer primary key,
			error_id integer,
			diagram_id integer,
			items text,
			description text
		);
		
		create table branches
		(
			diagram_id integer,		
			ordinal integer,

			header_icon integer,
			start_icon integer,
			params_icon integer,
			first_icon integer,
			
			primary key (diagram_id, ordinal)
		);
		
		create table links
		(
			src integer,
			ordinal integer,
			dst integer,
			direction text,
			constant text,
			primary key (src, ordinal)
		);
		
		create table declares
		(
			declare_id integer primary key,
			diagram_id integer,
			line text
		);
		
		create index declares_by_diagram on declares(diagram_id);
	}
}

proc get_error_list { } {
	set output {}
	gdb eval { delete from results }
	gdb eval {
		select d.name, e.diagram_id, error_id, items, message
		from errors e inner join diagrams d
			on e.diagram_id = d.diagram_id
		order by d.name, items
	} {
		if { [ llength $items ] > 0 } {
			set item_id [ lindex $items 0 ]
			set description "$name: item $item_id: $message"
		} else {
			set description "$name: $message"
		}
		lappend output $description
		gdb eval {
			insert into results (error_id, diagram_id, items, description)
			values ( :error_id, :diagram_id, :items, :description )
		}
	}
	
	return $output
}

proc get_error_info { error_no } {
	set result_id [ expr { $error_no + 1 } ]
	return [ gdb eval {
		select diagram_id, items
		from results
		where result_id = :result_id } ]
}

proc p.error { diagram_id items message } {
	if { $diagram_id == "" } {
		error "diagram_id is empty"
	}
	set existing [ gdb onecolumn {
		select count(*)
		from errors
		where diagram_id = :diagram_id
			and items = :items
			and message = :message } ]
	if { $existing != 0 } { return }
	gdb eval {
		insert into errors (diagram_id, items, message)
			values (:diagram_id, :items, :message) }
}

proc p.clear { } {
	gdb eval {
		delete from vertices;
		delete from edges;
		delete from errors;
		delete from results;
		delete from branches;
		delete from links;
	}
}

proc p.put_edges { diagram_id } {
	gdb eval {
		select item_id, type
		from items
		where diagram_id = :diagram_id
	} {
		if { $type == "vertical" } {
			p.put_line $item_id 1
		} elseif { $type == "horizontal" } {
			p.put_line $item_id 0
		} elseif { $type == "if" } {
			p.put_if_line $item_id
		} elseif { $type == "arrow" } {
			p.put_arrow $item_id
		}
	}
}

proc p.put_line { item_id vertical } {
	gdb eval {
		select item_id, diagram_id, type, text, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} {
		set point1 [ list $x $y ]
		set right [ expr { $x + $w } ]
		set bottom [ expr { $y + $h } ]
		set point2 [ list $right $bottom ]
		set items [ list $item_id ]
		
		gdb eval {
			insert into edges (diagram_id, point1, point2, head, vertical, items)
			values (:diagram_id, :point1, :point2, 0, :vertical, :items)
		}	
	}
}


proc p.put_if_line { item_id } {
	gdb eval {
		select item_id, diagram_id, type, text, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} {
		set left [ expr { $x + $w } ]
		set right [ expr { $left + $a } ]
		set point1 [ list $left $y ]
		set point2 [ list $right $y ]
		set items [ list $item_id ]
		
		gdb eval {
			insert into edges (diagram_id, point1, point2, head, vertical, items)
			values (:diagram_id, :point1, :point2, 0, 0, :items)
		}	
	}
}

proc p.put_arrow { item_id } {
	gdb eval {
		select item_id, diagram_id, type, text, x, y, w, h, a, b
		from items
		where item_id = :item_id
	} {
		set items [ list $item_id ]
		p.put_arrow_middle $items $diagram_id $x $y $h
		if { $b == 0 } {
			p.put_left_arrow $items $diagram_id $x $y $w $h $a
		} else {
			p.put_right_arrow $items $diagram_id $x $y $w $h $a
		}
	}
}


proc p.put_arrow_middle { items diagram_id x y h } {
	set bottom [ expr { $y + $h } ]
	set point1 [ list $x $y ]
	set point2 [ list $x $bottom ]
	gdb eval {
		insert into edges (diagram_id, point1, point2, head, vertical, items)
		values (:diagram_id, :point1, :point2, 0, 1, :items)
	}
}

proc p.put_left_arrow { items diagram_id x y w h a } {
	set bottom [ expr { $y + $h } ]
	set leftup [ expr { $x - $w } ]
	set leftdown [ expr { $x - $a } ]
	set upoint1 [ list $leftup $y ]
	set upoint2 [ list $x $y ]
	set dpoint1 [ list $leftdown $bottom ]
	set dpoint2 [ list $x $bottom ]
	gdb eval {
		insert into edges (diagram_id, point1, point2, head, vertical, items)
		values (:diagram_id, :upoint1, :upoint2, 1, 0, :items);
		
		insert into edges (diagram_id, point1, point2, head, vertical, items)
		values (:diagram_id, :dpoint1, :dpoint2, 0, 0, :items);
	}
}

proc p.put_right_arrow { items diagram_id x y w h a } {
	set bottom [ expr { $y + $h } ]
	set rightup [ expr { $x + $w } ]
	set rightdown [ expr { $x + $a }  ]
	set upoint1 [ list $x $y ]
	set upoint2 [ list $rightup $y ]
	set dpoint1 [ list $x $bottom ]
	set dpoint2 [ list $rightdown $bottom ]
	gdb eval {
		insert into edges (diagram_id, point1, point2, head, vertical, items)
		values (:diagram_id, :upoint1, :upoint2, 2, 0, :items);
		
		insert into edges (diagram_id, point1, point2, head, vertical, items)
		values (:diagram_id, :dpoint1, :dpoint2, 0, 0, :items);
	}
}

proc p.merge_lines { diagram_id } {
	p.check_arrows_dont_merge $diagram_id
	if { [ p.errors $diagram_id ] } {
		return
	}
	
	p.merge_par_lines $diagram_id 0
	p.merge_par_lines $diagram_id 1
	gdb eval {
		delete from edges
		where diagram_id = :diagram_id
		and marked = 1 }
}

proc p.check_arrows_dont_merge { diagram_id } {
	set lines [ gdb eval {
		select edge_id
		from edges
		where diagram_id = :diagram_id
			and vertical = 0
			and head = 0 } ]

	set arrows [ gdb eval {
		select edge_id
		from edges
		where diagram_id = :diagram_id
			and vertical = 0
			and head != 0 } ]
			
	foreach line $lines {
		set line_info [ gdb eval {
			select point1, point2
			from edges
			where edge_id = :line } ]
		unpack $line_info line_p1 line_p2
		set ly [ lindex $line_p1 1 ]
		set lx1 [ lindex $line_p1 0 ]
		set lx2 [ lindex $line_p2 0 ]
		
		foreach arrow $arrows {
			set arrow_info [ gdb eval {
				select point1, point2
				from edges
				where edge_id = :arrow } ]
			unpack $arrow_info arrow_p1 arrow_p2
			set ay [ lindex $arrow_p1 1 ]
			set ax1 [ lindex $arrow_p1 0 ]
			set ax2 [ lindex $arrow_p2 0 ]
			
			if { $ly == $ay && [ intervals_intersect $lx1 $lx2 $ax1 $ax2 ] } {
				p.unexpected_edge $line
			}
		}
	}
}

proc p.merge_par_lines { diagram_id vertical } {
	set lines [ gdb eval {
		select edge_id
		from edges
		where diagram_id = :diagram_id
			and vertical = :vertical
			and head = 0 } ]
			
	foreach edge_id $lines {
		gdb eval { 
			update edges
			set marked = 0
			where edge_id = :edge_id }
	}
	
	foreach edge1 $lines {
		set marked [ gdb onecolumn { 
			select marked
			from edges 
			where edge_id = :edge1 } ]
		if { $marked } { continue }
		foreach edge2 $lines {
			p.merge $edge1 $edge2 $vertical
		}
	}
}

proc p.merge { edge1 edge2 main_coord_index } {
	if { $edge1 == $edge2 } { return }
	set e2 [ gdb eval {
		select point1, point2, items, marked
		from edges
		where edge_id = :edge2 } ]
		
	unpack $e2 p21 p22 items2 marked
	if { $marked } { return }
	
	set e1 [ gdb eval { 
		select point1, point2, items
		from edges
		where edge_id = :edge1 } ]

	unpack $e1 p11 p12 items1
	set secondary_coord_index [ expr { !$main_coord_index } ]
	set secondary1 [ lindex $p11 $secondary_coord_index ]
	set secondary2 [ lindex $p21 $secondary_coord_index ]
	if { $secondary1 != $secondary2 } { return }
	set aleft [ lindex $p11 $main_coord_index ]
	set aright [ lindex $p12 $main_coord_index ]
	set bleft [ lindex $p21 $main_coord_index ]
	set bright [ lindex $p22 $main_coord_index ]
	unpack [ intervals_touch $aleft $aright $bleft $bright ] hit left right

	if { !$hit } { return }
	set point1 [ lreplace $p11 $main_coord_index $main_coord_index $left ]
	set point2 [ lreplace $p12 $main_coord_index $main_coord_index $right ]
	set items [ concat $items1 $items2 ]
	gdb eval {
		update edges
		set point1 = :point1, point2 = :point2, items = :items
		where edge_id = :edge1;

		update edges
		set marked = 1
		where edge_id = :edge2;
	}
}

proc p.put_vertices { diagram_id } {
	set edges [ gdb eval {
		select item_id
		from items
		where diagram_id = :diagram_id
			and type in ('action', 'address', 'beginend', 'branch',
				'case', 'if', 'insertion', 'loopend', 'loopstart', 'select') } ]
				
	foreach item_id $edges {
		p.put_vertex $item_id
	}
}

proc p.put_vertex { item_id } {
	gdb eval {
		select diagram_id, x, y, w, h, a, b, type
		from items
		where item_id = :item_id
	} {
		set other [ gdb onecolumn {
			select item_id from vertices
			where x = :x and y = :y 
				and diagram_id = :diagram_id } ]
		if { $other != "" } {
			p.error $diagram_id [ list $item_id $other ] "Two icons at the same position."
			return
		}
		
		p.find_intersections $item_id $diagram_id $x $y $w $h
		gdb eval {
			insert into vertices (diagram_id, x, y, w, h, a, b, item_id)
			values (:diagram_id, :x, :y, :w, :h, :a, :b, :item_id) }
	}
}

proc p.find_intersections { item_id diagram_id x y w h } {
	set my_rect [ make_rect $x $y $w $h ]
	unpack $my_rect mx my mx2 my2
	gdb eval {
		select item_id other
		from vertices
		where item_id != '' and item_id != :item_id
			and diagram_id = :diagram_id
	} {
		gdb eval {
			select x x2, y y2, w w2, h h2
			from items
			where item_id = :other
		} {
			set other_rect [ make_rect $x2 $y2 $w2 $h2 ]
			unpack $other_rect ox oy ox2 oy2
			if { [ rectangles_intersect $mx $my $mx2 $my2 $ox $oy $ox2 $oy2 ] } {
				p.error $diagram_id [ list $item_id $other ] "No space between icons."
			}
		}
	}
}

proc p.lines_to_vertices { diagram_id } {
	set edges [ gdb eval {
		select edge_id
		from edges
		where diagram_id = :diagram_id
			and head = 0
		order by edge_id } ]
	
	set vertices [ gdb eval {
		select vertex_id
		from vertices
		where diagram_id = :diagram_id } ]
		
	for { set i 0 } { $i < [ llength $edges ] } { incr i } {
		set edge_id [ lindex $edges $i ]
		foreach vertex_id $vertices {
			set new_edge_id [ p.line_to_icon $edge_id $vertex_id ]
			if { $new_edge_id != "" } {
				lappend edges $new_edge_id
			}
		}
	}
}

proc p.line_to_icon { edge_id vertex_id } {
	set edge [ gdb eval {
		select point1, point2, vertex1, vertex2, vertical, items, diagram_id
		from edges
		where edge_id = :edge_id } ]
	
	unpack $edge point1 point2 vertex1 vertex2 items
	
	if { $vertex1 == $vertex_id || $vertex2 == $vertex_id } {
		return ""
	}
	
	set icon [ gdb eval {
		select it.x, it.y, it.w, it.h, up, left, right, down, it.item_id
		from vertices v inner join items it
			on v.item_id = it.item_id
		where vertex_id = :vertex_id } ]
	unpack $icon x y w h

	set rect [ make_rect $x $y $w $h ]
	if { ![ line_hit_box $rect $point1 $point2 ] } {
		return ""
	}
	
	return [ p.line_to_icon_kernel $edge_id $vertex_id $edge $icon $rect ]
}

proc p.line_to_icon_kernel { edge_id vertex_id edge icon rect } {
	unpack $icon x y w h up left right down iitem
	unpack $edge point1 point2 vertex1 vertex2 vertical items diagram_id
	if { $vertical } {
		set parts [ box_cut_line_vertical $rect $point1 $point2 ]
	} else {
		set parts [ box_cut_line_horizontal $rect $point1 $point2 ]
	}
	set length [ llength $parts ]
	if { $length == 0 } {
		gdb eval {
			delete from edges
			where edge_id = :edge_id }
		return ""
	}
	set p1 [ lindex $parts 0 ]
	unpack $p1 side pt1 pt2

	if { [ p.buzy $up $left $right $down $vertical $side ] } {
		p.report_buzy_icon $iitem $items
		return ""
	}
	
	set edge_icon [ p.connect_edge_to_icon $edge_id $vertex_id $vertical $side $vertex1 $vertex2 $up $left $right $down ]
	unpack $edge_icon new_edge new_icon
	unpack $new_edge v1 v2
	unpack $new_icon up left right down
	gdb eval {
		update edges
		set point1 = :pt1, point2 = :pt2, vertex1 = :v1, vertex2 = :v2
		where edge_id = :edge_id;
		
		update vertices
		set up = :up, left = :left, right = :right, down = :down 
		where vertex_id = :vertex_id; }
	
	if { $length == 1 } {
		return ""
	}

	set p2 [ lindex $parts 1 ]
	unpack $p2 side pt1 pt2

	if { [ p.buzy $up $left $right $down $vertical $side ] } {
		p.report_buzy_icon $iitem $items
		return ""
	}
	
	set edge_id2 [ mod::next_key gdb edges edge_id ]
	set edge_icon [ p.connect_edge_to_icon $edge_id2 $vertex_id $vertical $side $vertex1 $vertex2 $up $left $right $down ]
	unpack $edge_icon new_edge new_icon
	unpack $new_edge v1 v2

	unpack $new_icon up left right down
	
	gdb eval {
		insert into edges (edge_id, diagram_id, point1, point2, vertex1, vertex2, head, vertical, items)
		values (:edge_id2, :diagram_id, :pt1, :pt2, :v1, :v2, 0, :vertical, :items);
		
		update vertices
		set up = :up, left = :left, right = :right, down = :down 
		where vertex_id = :vertex_id; }
	return $edge_id2
}

proc p.report_buzy_icon { icon_item edge_items } {
	lappend edge_items $icon_item
	set diagram_id [ gdb onecolumn {
		select diagram_id
		from items
		where item_id = :icon_item } ]
	p.error $diagram_id $edge_items "This icon has several lines on its side."
}

proc p.connect_edge_to_icon { edge_id vertex_id vertical side vertex1 vertex2 up left right down } {
	if { $vertical } {
		if { $side == 1 } {
			set down $edge_id
		} else {
			set up $edge_id
		}
	} else {
		if { $side == 1 } {
			set right $edge_id
		} else {
			set left $edge_id
		}
	}
	
	if { $side == 1 } {
		set vertex1 $vertex_id
	} else {
		set vertex2 $vertex_id
	}
	
	set new_edge [ list $vertex1 $vertex2 ]
	set new_icon [ list $up $left $right $down ]
	return [ list $new_edge $new_icon ]
}

proc p.buzy { up left right down vertical side } {
	if { $vertical } {
		if { $side == 1 } {
			set slot $down
		} else {
			set slot $up
		}
	} else {
		if { $side == 1 } {
			set slot $right
		} else {
			set slot $left
		}
	}
	return [ expr { $slot != "" } ]
}

proc p.put_caps { diagram_id } {
	gdb eval {
		select edge_id, point1, point2, vertical, items, vertex1, vertex2
		from edges
		where diagram_id = :diagram_id
	} {
		if { $vertex1 == "" } {
			p.put_cap $diagram_id $edge_id $point1 $point2 $vertical 1 $items
		}
		if { $vertex2 == "" } {
			p.put_cap $diagram_id $edge_id $point1 $point2 $vertical 2 $items
		}
	}
}

proc p.put_cap { diagram_id edge_id point1 point2 vertical side items } {
	set vs [ gdb eval { select vertex1, vertex2 from
		edges where edge_id = :edge_id } ]
	unpack $vs vertex1 vertex2
	if { $side == 1 } {
		unpack $point1 x y
	} else {
		unpack $point2 x y	
	}
	set vertex [ gdb eval {
		select vertex_id, up, left, right, down
		from vertices
		where diagram_id = :diagram_id
			and x = :x and y = :y } ]
	unpack $vertex vertex_id up left right down
	
	if { $vertex == "" } {
		set vertex_id [ mod::next_key gdb vertices vertex_id ]
		gdb eval {
			insert into vertices (vertex_id, x, y, diagram_id)
			values (:vertex_id, :x, :y, :diagram_id);
		}
	} else {
		if { [ p.buzy $up $left $right $down $vertical $side ] } {
			p.error $diagram_id $items "Line should not be under arrow."
			return
		}
	}
	
	set edge_icon [ p.connect_edge_to_icon $edge_id $vertex_id $vertical $side \
		$vertex1 $vertex2 $up $left $right $down ]
	unpack $edge_icon new_edge new_icon
	unpack $new_edge v1 v2
	unpack $new_icon up left right down
	gdb eval {
		update edges
		set vertex1 = :v1, vertex2 = :v2
		where edge_id = :edge_id;
		
		update vertices
		set up = :up, left = :left, right = :right, down = :down 
		where vertex_id = :vertex_id; }
}

proc p.errors { diagram_id } {
	set count [ gdb onecolumn {
		select count(*) from errors
		where diagram_id = :diagram_id } ]
	return [ expr { $count > 0 } ]
}

proc p.lines { diagram_id vertical } {
	set lines [ gdb eval {
		select edge_id
		from edges
		where diagram_id = :diagram_id
			and vertical = $vertical } ]
	return $lines
}


proc p.t_joins { diagram_id } {
	set vlines [ p.lines $diagram_id 1 ]

	for { set i 0 } { $i < [ llength $vlines ] } { incr i } {	
		set ver [ lindex $vlines $i ]
		foreach hor [ p.lines $diagram_id 0 ] {
			set new_vertical [ p.t_join $diagram_id $hor $ver ]
			if { $new_vertical != "" } {
				lappend vlines $new_vertical
			}
		}
	}
	if { [ p.errors $diagram_id ] } { return }
	foreach hor [ p.lines $diagram_id 0 ] {
		foreach ver [ p.lines $diagram_id 1 ] {
			p.t_join $diagram_id $ver $hor
		}
	}
}

proc p.t_join { diagram_id main_road branch_road } {
	set main [ gdb eval {
		select point1, point2, vertex1, vertex2, items, vertical, head
		from edges
		where edge_id = :main_road } ]
	unpack $main mpoint1 mpoint2 mvertex1 mvertex2 mitems mvertical mhead
	
	set branch [ gdb eval {
		select point1, point2, vertex1, vertex2, items, vertical
		from edges
		where edge_id = :branch_road } ]
	unpack $branch bpoint1 bpoint2 bvertex1 bvertex2 bitems bvertical
	
	if { $mvertical } {
		set result [ intersect_lines_leftright $mpoint1 $mpoint2 $bpoint1 $bpoint2 ]
	} else {
		set result [ intersect_lines_updown $mpoint1 $mpoint2 $bpoint1 $bpoint2 ]
	}
	
	unpack $result code x y
	
	switch $code {
		"none" {
		}
		"crossing_ud" {
			set new_down [ p.make_crossing $diagram_id $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems $mhead \
				$branch_road $bpoint1 $bpoint2 $bvertex1 $bvertex2 $bitems $x $y ]
			return $new_down
		}
		"up" {
			set new_edge [ p.split $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems \
				$mvertical $mhead $bvertex2 $x $y ]
			p.check_leftright $bvertex2 $mitems
			gdb eval {
				update vertices
				set left = :main_road, right = :new_edge
				where vertex_id = :bvertex2;
				
				update vertices
				set left = :new_edge
				where vertex_id = :mvertex2;
			}
		}
		"down" {
			set new_edge [ p.split $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems \
				$mvertical $mhead $bvertex1 $x $y ]
			p.check_leftright $bvertex1 $mitems
			gdb eval {
				update vertices
				set left = :main_road, right = :new_edge
				where vertex_id = :bvertex1;
				
				update vertices
				set left = :new_edge
				where vertex_id = :mvertex2;				
			}
		}
		"left" {
			set new_edge [ p.split $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems \
				$mvertical $mhead $bvertex2 $x $y ]
			p.check_updown $bvertex2 $mitems
			gdb eval {
				update vertices
				set up = :main_road, down = :new_edge
				where vertex_id = :bvertex2;

				update vertices
				set up = :new_edge
				where vertex_id = :mvertex2;	
			}				
		}
		"right" {
			set new_edge [ p.split $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems \
				$mvertical $mhead $bvertex1 $x $y ]
			p.check_updown $bvertex1 $mitems
			gdb eval {
				update vertices
				set up = :main_road, down = :new_edge
				where vertex_id = :bvertex1;

				update vertices
				set up = :new_edge
				where vertex_id = :mvertex2;	
			}
		}
		default {
			error "Unexpected intersection result: $code"
		}
	}
	return ""
}

proc p.check_leftright { vertex_id items } {
	gdb eval {
		select diagram_id, left, right
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $left != "" || $right != "" } {
			p.error $diagram_id $items "Arrow coinsides with a line."
			return 0
		}
	}
	return 1
}

proc p.check_updown { vertex_id items } {
	gdb eval {
		select diagram_id, up, down
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $up != "" || $down != "" } {
			p.error $diagram_id $items "Arrow coinsides with a line."
			return 0
		}
	}
	return 1
}

proc p.make_crossing { diagram_id main_road mpoint1 mpoint2 mvertex1 mvertex2 mitems mhead
				branch_road bpoint1 bpoint2 bvertex1 bvertex2 bitems x y } {
	gdb eval {
		select vertical
		from edges
		where edge_id = :main_road
	} {
		if { $vertical != 0 } {
			error "p.make_crossing: Main road should be horizontal."
		}
	}
	set existing [ gdb onecolumn {
		select count(*)
		from vertices
		where x = :x and y = :y
			and diagram_id = :diagram_id } ]
			
	if { $existing != 0 } {
		p.error $diagram_id $mitems "Unexpected elements"
		return
	}
	
	set new_vertex [ mod::next_key gdb vertices vertex_id ]
	gdb eval {
		insert into vertices (vertex_id, diagram_id, x, y)
		values (:new_vertex, :diagram_id, :x, :y) }
		
	set edge_down [ p.split $branch_road $bpoint1 $bpoint2 $bvertex1 $bvertex2 $bitems 1 0 $new_vertex $x $y ]
	set edge_right [ p.split $main_road $mpoint1 $mpoint2 $mvertex1 $mvertex2 $mitems 0 $mhead $new_vertex $x $y ]
	
	gdb eval {
		update vertices
		set left = :main_road, up = :branch_road, right = :edge_right, down = :edge_down
		where vertex_id = :new_vertex;
		
		update vertices
		set left = :edge_right
		where vertex_id = :mvertex2;
		
		update vertices
		set up = :edge_down
		where vertex_id = :bvertex2;
	}
	return $edge_down
}

proc p.split { main_road mpoint1 mpoint2 mvertex1 mvertex2 mitems
				mvertical mhead bvertex x y } {
	set new_edge [ mod::next_key gdb edges edge_id ]	
	set middle [ list $x $y ]
	if { $mhead == 1 } {
		set head_old 1
		set head_new 0		
	} elseif { $mhead == 2 } {
		set head_old 0
		set head_new 2	
	} else {
		set head_old 0
		set head_new 0
	}
	set diagram_id [ gdb onecolumn {
		select diagram_id from edges where edge_id = :main_road } ]
	gdb eval {
		update edges
		set point2 = :middle, vertex2 = :bvertex, head = :head_old
		where edge_id = :main_road;

		insert into edges (edge_id, diagram_id, point1, point2, vertex1, vertex2, vertical, head, items)
			values (:new_edge, :diagram_id, :middle, :mpoint2, :bvertex, :mvertex2, :mvertical, :head_new, :mitems);
	}
	return $new_edge
}

proc p.do_build_graph { diagram_id } {
	p.put_edges $diagram_id
	p.put_vertices $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.merge_lines $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.lines_to_vertices $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.put_caps $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.t_joins $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.dangling $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.on_same_line $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	
	p.disjoined $diagram_id
	if { [ p.errors $diagram_id ] } { return }
}

proc p.on_same_line { diagram_id } {
	gdb eval {
		select vertex_id, up, left, right, down, item_id, diagram_id
		from vertices
		where diagram_id = :diagram_id
	} {
		if { $up != "" && $down != "" } {
			set line1 [ gdb eval {
				select point2, items
				from edges
				where edge_id  = :up } ]
			unpack $line1 p1 items1

			set line2 [ gdb eval {
				select point1, items
				from edges
				where edge_id  = :down } ]
			unpack $line2 p2 items2
			
			set x1 [ lindex $p1 0 ]
			set x2 [ lindex $p2 0 ]

			if { $x1 != $x2 } {
				set items [ concat $items1 $items2 ]
				p.error $diagram_id $items "Broken vertical line."
			}
		}
		
		if { $left != "" && $right != "" } {
			set line1 [ gdb eval {
				select point2, items
				from edges
				where edge_id  = :left } ]
			unpack $line1 p1 items1
			
			set line2 [ gdb eval {
				select point1, items
				from edges
				where edge_id  = :right } ]
			unpack $line2 p2 items2
			set y1 [ lindex $p1 1 ]
			set y2 [ lindex $p2 1 ]
			if { $y1 != $y2 } {
				set items [ concat $items1 $items2 ]
				p.error $diagram_id $items "Broken horizontal line."
			}
		}		
	}
}
proc p.dangling { diagram_id } {
	gdb eval {
		select vertex_id, up, left, right, down, item_id, diagram_id
		from vertices
		where diagram_id = :diagram_id
			and item_id is null
	} {
		set connections 0
		if { $up != "" } {
			set edge $up
			incr connections
		}
		if { $left != "" } {
			set edge $left
			incr connections
		}
		if { $right != "" } {
			set edge $right
			incr connections
		}
		if { $down != "" } {
			set edge $down
			incr connections
		}
		
		if { $connections == 0 } { error "inconsistent graph: vertex $vertex_id" }
		if { $connections == 1 } {
			set items [ gdb onecolumn {
				select items
				from edges
				where edge_id = :edge } ]
			p.error $diagram_id $items "Line not connected to any icon."
		}
	}
}

proc p.disjoined { diagram_id } {
	gdb eval {
		update vertices
		set marked = 0
		where diagram_id = :diagram_id }
	
	set start [ gdb onecolumn {
		select min(vertex_id)
		from vertices
		where diagram_id = :diagram_id } ]
			
	p.disjoined_recursive $start
	set total [ gdb onecolumn { 
		select count(*)
		from vertices
		where diagram_id = :diagram_id } ]
	set visited [ gdb onecolumn { 
		select count(*)
		from vertices
		where diagram_id = :diagram_id 
			and marked = 1} ]
	
	if { $total != $visited } {
		p.error $diagram_id {} "All icons must be connected together."
	}
}

proc 	p.disjoined_recursive { vertex_id } {
	gdb eval {
		select up, left, right, down, marked
		from vertices
		where vertex_id = :vertex_id
	} {
		if { $marked } { return }
		gdb eval {
			update vertices
			set marked = 1
			where vertex_id = :vertex_id
		}
		
		if { $up != "" } {
			set next [ gdb onecolumn {
				select vertex1
				from edges
				where edge_id  = :up } ]
			
			p.disjoined_recursive $next
		}

		if { $down != "" } {
			set next [ gdb onecolumn {
				select vertex2
				from edges
				where edge_id  = :down } ]
			
			p.disjoined_recursive $next
		}
		
		if { $left != "" } {
			set next [ gdb onecolumn {
				select vertex1
				from edges
				where edge_id  = :left } ]
			
			p.disjoined_recursive $next
		}

		if { $right != "" } {
			set next [ gdb onecolumn {
				select vertex2
				from edges
				where edge_id  = :right } ]
			
			p.disjoined_recursive $next
		}
	}
}

proc build_graph { db diagram_id } {
	copy_from $db
	p.do_build_graph $diagram_id
}

proc verify_one { db diagram_id } {
	copy_from $db
	p.do_build_graph $diagram_id
	if { [ p.errors $diagram_id ] } { return }
	p.do_extract_auto $diagram_id
}

proc verify_all { db } {
	copy_from $db
	$db eval {
		select diagram_id
		from diagrams
	} {
		p.do_build_graph $diagram_id
		if { [ p.errors $diagram_id ] } { continue }
		p.do_extract_auto $diagram_id
	}
}

proc errors_occured { } {
	set count [ gdb onecolumn {
		select count(*)
		from errors } ]
	return [ expr { $count > 0 } ]
}

}
