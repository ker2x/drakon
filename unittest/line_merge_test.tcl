

proc check_line_merge { diagram_name merged_lines } {
	set diagram_id [ ddd onecolumn { 
		select diagram_id from diagrams where name = :diagram_name } ]
	if { $diagram_id == "" } {
		error "Diagram $diagram_name not found"
	}
	graph::p.clear
	graph::p.put_edges $diagram_id
	graph::p.put_vertices $diagram_id
	graph::p.merge_lines $diagram_id
	
	
	set actual_count [ gdb onecolumn {
		select count(*) from edges
		where diagram_id = :diagram_id } ]
	equal $actual_count [ llength $merged_lines ]

	foreach expected $merged_lines {
		unpack $expected x1 y1 x2 y2 items
		check_edge_exist $diagram_id $x1 $y1 $x2 $y2 $items
	}
}

proc check_overlap { diagram_name errors } {
	set diagram_id [ ddd onecolumn { 
		select diagram_id from diagrams where name = :diagram_name } ]
	if { $diagram_id == "" } {
		error "Diagram $diagram_name not found"
	}
	graph::p.clear
	graph::p.put_edges $diagram_id
	graph::p.put_vertices $diagram_id

	foreach err $errors {
		unpack $err items message
		check_error_reported $diagram_id $items $message
	}
}

proc check_error_reported { diagram_id items message } {

	gdb eval {
		select items actual_items
		from errors
		where diagram_id = :diagram_id
			and message = :message
	} {
		
		set actual_items [ lsort -dictionary $actual_items ]
		if { $actual_items == $items } {
			return
		}
	}
	error "error not found: diagram:$diagram_id $items $message"
}

proc check_edge_exist { diagram_id x1 y1 x2 y2 items } {
	gdb eval {
		select point1, point2, items actual_items
		from edges
		where diagram_id = :diagram_id
	} {
		unpack $point1 ax1 ay1
		unpack $point2 ax2 ay2
		set actual_items [ lsort -dictionary $actual_items ]
		if { $ax1 == $x1 && $ay1 == $y1 &&
			$ax2 == $x2 && $ay2 == $y2 } {
			list_equal $actual_items $items
			return
		}
	}
	error "edge not found $x1 $y1 $x2 $y2 $items"
}

proc check_arrow_head { item_id x y } {
	gdb eval {
		select point1, point2, items, head
		from edges
	} {
		set actual_item [ lindex $items 0 ]
		if { $actual_item == $item_id } {
			unpack $point1 ax1 ay1
			unpack $point2 ax2 ay2
			if { $x == $ax1 && $y == $ay1 && $head == 1 } { return }
			if { $x == $ax2 && $y == $ay2 && $head == 2} { return }
		}
	}
	error "arrow edge not found $item_id $x $y"
}

#####
proc arrow_test { } {
	check_line_merge arrow {
		{140  60 250  60 {31} }
		{250  60 250 280 {31} }
		{120 280 250 280 {31 32} }
	}
	check_arrow_head 31 140 60
}

proc arrow_right_test { } {
	check_line_merge arrow_right {
		{100  70 160  70 {33} }
		{100  70 100 270 {33} }
		{100 270 350 270 {33 34} }
	}
	check_arrow_head 33 160 70
}

####

proc disjoint_horizontal_test { } {
	check_line_merge disjoint_horizontal {
		{ 70  120 240 120 {4} }
		{ 440 120 500 120 {2} }
		{ 510 120 570 120 {3} }
		{ 370 120 430 120 {1} }
	}
}

proc disjoint_vertical_test { } {
	check_line_merge disjoint_vertical {
		{ 140 60  140 160 {5} }
		{ 140 180 140 280 {6} }
		{ 140 300 140 410 {7} }
	}
}

###

proc horizontal_coinside_test { } {
	check_line_merge joint_horizontal_coinside {
		{ 180 220 320 220 {13 14} }
	}
}

proc horizontal_edge_test { } {
	check_line_merge joint_horizontal_edge {
		{ 60 60 330 60 {8 9 10} }
	}
}

proc horizontal_inside_test { } {
	check_line_merge joint_horizontal_inside {
		{ 70 220 320 220 {15 16} }
	}
}

proc horizontal_overlap_test { } {
	check_line_merge joint_horizontal_overlap {
		{ 90 130 310 130 {11 12} }
	}
}

#####



proc vertical_coinside_test { } {
	check_line_merge joint_vertical_coinside {
		{ 140 80 140 280 {19 20} }
	}
}

proc vertical_edge_test { } {
	check_line_merge joint_vertical_edge {
		{ 150 30 150 290 {23 24} }
	}
}

proc vertical_inside_test { } {
	check_line_merge joint_vertical_inside {
		{ 170 80 170 370 {27 28} }
	}
}

proc vertical_overlap_test { } {
	check_line_merge joint_vertical_overlap {
		{ 180 50 180 270 {29 30} }
	}
}

#####

proc horizontal_many_test { } {
	check_line_merge horizontal_many {
		{  90  90 270  90 {35 36 37} }
		{ 310  90 370  90 {38} }
		{ 240 150 320 150 {39} }
	}
}

proc vertical_many_test { } {
	check_line_merge vertical_many {
		{ 120  80 120 220 {40 41 42} }
		{ 120 240 120 410 {43 44} }
		{ 240 200 240 300 {45} }
	}
}
#####

tproc line_merge_test { } {
	sqlite3 ddd ../testdata/line_merge.drn
	graph::copy_from ddd
	
	arrow_test
	arrow_right_test

	disjoint_horizontal_test
	disjoint_vertical_test

	
	
	horizontal_coinside_test
	horizontal_edge_test
	horizontal_inside_test
	horizontal_overlap_test

	vertical_coinside_test
	vertical_edge_test
	vertical_inside_test
	vertical_overlap_test

	horizontal_many_test
	vertical_many_test
	
	check_overlap same_position {{ {52 53} "Two icons at the same position." }}
	check_overlap overlap {
		{ {48 49} "No space between icons." }
		{ {50 51} "No space between icons." } }		
	
	ddd close
}


