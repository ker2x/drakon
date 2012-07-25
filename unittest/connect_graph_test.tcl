
proc load_normal_db { diagram_name } {
	set diagram_id [ ddd onecolumn { 
		select diagram_id from diagrams where name = :diagram_name } ]
	if { $diagram_id == "" } {
		error "Diagram $diagram_name not found"
	}
	graph::p.clear
	graph::p.put_edges $diagram_id
	graph::p.put_vertices $diagram_id
	graph::p.merge_lines $diagram_id
	if { [ graph::p.errors $diagram_id ] } { return $diagram_id }
	graph::p.lines_to_vertices $diagram_id
	graph::p.put_caps $diagram_id
	graph::p.t_joins $diagram_id
	return $diagram_id
}

proc expect_errors { diagram_name count } {
	set diagram_id [ load_normal_db $diagram_name ]
	equal [ gdb onecolumn {
		select count(*) from errors } ] $count
		
	if { 0 } {
		print_errors $diagram_name $diagram_id
	}		
}

proc check_integrity { diagram_id } {
	#print_edgs
	equal [ gdb onecolumn { select count(*) from errors where diagram_id = :diagram_id } ] 0
	equal [ gdb onecolumn { select count(*) from edges
		where (vertex1 = '' or vertex2 = '')
			and diagram_id = :diagram_id } ] 0
	gdb eval {
		select vertex_id, up, left, right, down
		from vertices
		where diagram_id = :diagram_id
	} {
		if { $up != "" } {
			set count [ gdb onecolumn {
				select count(*)
				from edges
				where diagram_id = :diagram_id
					and vertical = 1
					and vertex2 = :vertex_id
					and edge_id = :up } ]
			equal $count 1
		}
		
		if { $down != "" } {
			set count [ gdb onecolumn {
				select count(*)
				from edges
				where diagram_id = :diagram_id
					and vertical = 1
					and vertex1 = :vertex_id
					and edge_id = :down } ]
			equal $count 1
		}		
		
		if { $left != "" } {
			set count [ gdb onecolumn {
				select count(*)
				from edges
				where diagram_id = :diagram_id
					and vertical = 0
					and vertex2 = :vertex_id
					and edge_id = :left } ]
			equal $count 1
		}		

		if { $right != "" } {
			set count [ gdb onecolumn {
				select count(*)
				from edges
				where diagram_id = :diagram_id
					and vertical = 0
					and vertex1 = :vertex_id
					and edge_id = :right } ]
			equal $count 1
		}
	}
	
	if { 0 } {
		print_ev $diagram_id
	}
	
	gdb eval {
		select vertex1, vertex2, edge_id, vertical
		from edges
		where diagram_id = :diagram_id
	} {

		if { $vertex1 == "" || $vertex2 == "" } {
			error "Edge $edge_id has at least one empty end"
		}
		if { !$vertical } {
			set from_left [ gdb onecolumn {
				select right
				from vertices
				where vertex_id = :vertex1 } ]
			set from_right [ gdb onecolumn {
				select left
				from vertices
				where vertex_id = :vertex2 } ]
			
			if { $from_left != "" } {
				equal $from_left $edge_id
			}

			if { $from_right != "" } {
				equal $from_right $edge_id
			}
		} else {
			set from_top [ gdb onecolumn {
				select down
				from vertices
				where vertex_id = :vertex1 } ]
			set from_bottom [ gdb onecolumn {
				select up
				from vertices
				where vertex_id = :vertex2 } ]
			
			if { $from_top != "" } {
				equal $from_top $edge_id
			}

			if { $from_bottom != "" } {
				equal $from_bottom $edge_id
			}
		}
	}
}

proc print_ev { diagram_id } {
	gdb eval {
		select vertex1, vertex2, edge_id, vertical
		from edges
		where diagram_id = :diagram_id
		order by edge_id
	} {
		puts "e=$edge_id\tv1=$vertex1\tv2=$vertex2\tvert=$vertical"
	}
	puts --------------
	gdb eval {
		select vertex_id, left, up, right, down
		from vertices
		where diagram_id = :diagram_id
		order by vertex_id
	} {
		puts "v=$vertex_id\tu=$up\tl=$left\tr=$right\td=$down"
	}
}

proc get_icon_line { diagram_name icon_item line_item } {
	set diagram_id [ load_normal_db $diagram_name ]
	check_integrity $diagram_id
	set vertex [ gdb eval { 
		select vertex_id, left, right, up, down
		from vertices
		where item_id = :icon_item 
		and diagram_id = :diagram_id } ]
	if { $vertex == "" } {
		error "Icon $icon_item not found."
	}
	
	set items [ list $line_item ]
	set edges {}
	gdb eval {
		select edge_id, vertex1, vertex2
		from edges
		where items = :items
		and diagram_id = :diagram_id
	} {
		lappend edges [ list $edge_id $vertex1 $vertex2 ]
	}

	return [ list $vertex $edges ]
}

proc check_edge_count { diagram_name count } {
	set diagram_id [ load_normal_db $diagram_name ]
	check_integrity $diagram_id
	equal [ gdb onecolumn {
		select count(*)
		from edges
		where diagram_id = :diagram_id } ] $count
}

proc print_edgs { } { 
	puts \n\n\n
	gdb eval {
		select * from edges } row {
		parray row }
}

proc check_vertex_count { diagram_name count } {
	set diagram_id [ load_normal_db $diagram_name ]
	check_integrity $diagram_id
	equal [ gdb onecolumn {
		select count(*)
		from vertices
		where diagram_id = :diagram_id } ] $count
}


proc check_up_link { diagram_name icon_item line_item } {
	set icon_line [ get_icon_line $diagram_name $icon_item $line_item ]
	unpack $icon_line vertex edges
	unpack $vertex vertex_id left right up down
	foreach edge $edges {
		unpack $edge edge_id vertex1 vertex2
		if { $vertex2 == $vertex_id && $up == $edge_id } { 
			return 
		}
	}
	error "up: Edge $line_item not found."
}


proc check_down_link { diagram_name icon_item line_item } {
	set icon_line [ get_icon_line $diagram_name $icon_item $line_item ]
	unpack $icon_line vertex edges
	unpack $vertex vertex_id left right up down
	foreach edge $edges {
		unpack $edge edge_id vertex1 vertex2
		if { $vertex1 == $vertex_id && $down == $edge_id } { 
			return 
		}
	}
	error "down: Edge $line_item not found."
}

proc check_left_link { diagram_name icon_item line_item } {
	set icon_line [ get_icon_line $diagram_name $icon_item $line_item ]
	unpack $icon_line vertex edges
	unpack $vertex vertex_id left right up down
	foreach edge $edges {
		unpack $edge edge_id vertex1 vertex2
		if { $vertex2 == $vertex_id && $left == $edge_id } { 
			return 
		}
	}
	error "left: Edge $line_item not found."
}

proc check_right_link { diagram_name icon_item line_item } {
	set icon_line [ get_icon_line $diagram_name $icon_item $line_item ]
	unpack $icon_line vertex edges
	unpack $vertex vertex_id left right up down
	foreach edge $edges {
		unpack $edge edge_id vertex1 vertex2
		if { $vertex1 == $vertex_id && $right == $edge_id } { 
			return 
		}
	}
	error "right: Edge $line_item not found."
}


tproc icon_buzy_test { } {
	equal [ graph::p.buzy "" "" "" "" 0 1 ] 0
	equal [ graph::p.buzy "" "" "" "" 0 2 ] 0
	equal [ graph::p.buzy "" "" "" "" 1 1 ] 0
	equal [ graph::p.buzy "" "" "" "" 1 2 ] 0
	
	equal [ graph::p.buzy "" "" 5 "" 0 1 ] 1
	equal [ graph::p.buzy "" 5 "" "" 0 2 ] 1
	equal [ graph::p.buzy "" "" "" 5 1 1 ] 1
	equal [ graph::p.buzy 5 "" "" "" 1 2 ] 1
}

tproc connect_edge_to_icon_test { } {
#edge_id vertex_id vertical side vertex1 vertex2 up left right down
	list_equal [ graph::p.connect_edge_to_icon 200 400 0 1 20 30 11 12 13 14 ] {{400 30} {11 12 200 14}}
	list_equal [ graph::p.connect_edge_to_icon 200 400 0 2 20 30 11 12 13 14 ] {{20 400} {11 200 13 14}}
	list_equal [ graph::p.connect_edge_to_icon 200 400 1 1 20 30 11 12 13 14 ] {{400 30} {11 12 13 200}}
	list_equal [ graph::p.connect_edge_to_icon 200 400 1 2 20 30 11 12 13 14 ] {{20 400} {200 12 13 14}}
}

tproc connect_graph_test { } {
	sqlite3 ddd ../testdata/connect_graph.drn
	graph::copy_from ddd

#up
	check_up_link up 1 2
	check_up_link up 3 4
	check_up_link up 5 6
	
#left
	check_left_link left 13 14
	check_left_link left 15 16
	check_left_link left 17 18

#right
	check_right_link right 19 20
	check_right_link right 21 22
	check_right_link right 23 24

#down
	check_down_link down 7 8
	check_down_link down 9 10
	check_down_link down 11 12

#through
	check_up_link through 25 26
	check_down_link through 25 26

	check_up_link through 27 26
	check_down_link through 27 26

	check_up_link through 28 26
	check_down_link through 28 26
	
	check_left_link through 29 32
	check_right_link through 29 32

	check_left_link through 30 32
	check_right_link through 30 32

	check_left_link through 31 32
	check_right_link through 31 32

	check_edge_count through 8
	
#through2

# actions:
#	33 34
#	35 36

# lines:
# 		39
# 37		38
#		40

	check_up_link through2 33 37
	check_down_link through2 33 37
	check_up_link through2 35 37
	check_down_link through2 35 37


	check_up_link through2 34 38
	check_down_link through2 34 38
	check_up_link through2 36 38
	check_down_link through2 36 38

	check_left_link through2 33 39
	check_right_link through2 33 39
	check_left_link through2 34 39
	check_right_link through2 34 39	

	check_left_link through2 35 40
	check_right_link through2 35 40
	check_left_link through2 36 40
	check_right_link through2 36 40	

	check_edge_count through2 12
	check_edge_count inside 0
	check_vertex_count through2 12

	check_vertex_count square 4
	check_edge_count square 4
	expect_errors bad_arrows 4

#error asdf
	ddd close
}


proc find_icon { diagram_id text } {
	gdb eval {
		select vertex_id
		from vertices v inner join items it 
			on it.item_id = v.item_id
		where it.text = :text
			and it.diagram_id = :diagram_id
	} {
		return $vertex_id
	}
	error "Icon with text $text not found on diagram $diagram_id"
}

proc up_empty { vertex_id } {
	set v [ gdb onecolumn {
		select up
		from vertices
		where vertex_id = :vertex_id } ]
	equal $v ""
}

proc down_empty { vertex_id } {
	set v [ gdb onecolumn {
		select down
		from vertices
		where vertex_id = :vertex_id } ]
	equal $v ""
}

proc left_empty { vertex_id } {
	set v [ gdb onecolumn {
		select left
		from vertices
		where vertex_id = :vertex_id } ]
	equal $v ""
}

proc right_empty { vertex_id } {
	set v [ gdb onecolumn {
		select right
		from vertices
		where vertex_id = :vertex_id } ]
	equal $v ""
}


proc go_left { vertex_id } {
	set left_edge [ gdb onecolumn {
		select left
		from vertices
		where vertex_id = :vertex_id } ]
	if { $left_edge == "" } {
		error "left is empty for $vertex_id"
	}
	
	set left_vertex [ gdb onecolumn {
		select vertex1
		from edges
		where edge_id = :left_edge } ]
	if { $left_vertex == "" } {
		error "vertex1 is empty for $edge_id"
	}
	
	return $left_vertex
}

proc go_right { vertex_id } {
	set right_edge [ gdb onecolumn {
		select right
		from vertices
		where vertex_id = :vertex_id } ]
	if { $right_edge == "" } {
		error "right is empty for $vertex_id"
	}
	
	set right_vertex [ gdb onecolumn {
		select vertex2
		from edges
		where edge_id = :right_edge } ]
	if { $right_vertex == "" } {
		error "vertex2 is empty for $edge_id"
	}
	
	return $right_vertex
}

proc go_up { vertex_id } {
	set up_edge [ gdb onecolumn {
		select up
		from vertices
		where vertex_id = :vertex_id } ]
	if { $up_edge == "" } {
		error "up is empty for $vertex_id"
	}
	
	set up_vertex [ gdb onecolumn {
		select vertex1
		from edges
		where edge_id = :up_edge } ]
	if { $up_vertex == "" } {
		error "vertex1 is empty for $edge_id"
	}
	
	return $up_vertex
}

proc go_down { vertex_id } {
	set down_edge [ gdb onecolumn {
		select down
		from vertices
		where vertex_id = :vertex_id } ]
	if { $down_edge == "" } {
		error "down is empty for $vertex_id"
	}
	
	set down_vertex [ gdb onecolumn {
		select vertex2
		from edges
		where edge_id = :down_edge } ]
	if { $down_vertex == "" } {
		error "vertex2 is empty for $edge_id"
	}
	
	return $down_vertex
}

proc check_icon_text { vertex_id text } {
	set actual [ gdb onecolumn {
		select it.text
		from vertices v inner join items it
			on v.item_id = it.item_id
		where vertex_id = :vertex_id } ]
		
	equal $actual $text
}

tproc tjoin_test { } {
	sqlite3 ddd ../testdata/tjoins.drn
	graph::copy_from ddd
	
	#up
	set diagram_id [ load_normal_db up ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id left	 ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	check_icon_text $v up1
	
	set v [ go_down $v ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	check_icon_text $v up2
	
	set v [ go_down $v ]
	set v [ go_right $v ]
	check_icon_text $v right
	
	set v [ go_left $v ]
	set v [ go_left $v ]
	set v [ go_left $v ]	
	check_icon_text $v left



	#down
	set diagram_id [ load_normal_db down ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id left	 ]
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v down1

	set v [ go_up $v ]	
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v down2
	
	set v [ go_up $v ]
	set v [ go_right $v ]
	check_icon_text $v right
	
	set v [ go_left $v ]
	set v [ go_left $v ]
	set v [ go_left $v ]	
	check_icon_text $v left
	
	
	#left
	set diagram_id [ load_normal_db left ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id up ]
	set v [ go_down $v ]
	set v [ go_left $v ]
	check_icon_text $v left1

	set v [ go_right $v ]	
	set v [ go_down $v ]
	set v [ go_left $v ]
	check_icon_text $v left2
	
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v down
	
	set v [ go_up $v ]
	set v [ go_up $v ]
	set v [ go_up $v ]	
	check_icon_text $v up


	#right
	set diagram_id [ load_normal_db right ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id up ]
	set v [ go_down $v ]
	set v [ go_right $v ]
	check_icon_text $v right1

	set v [ go_left $v ]	
	set v [ go_down $v ]
	set v [ go_right $v ]
	check_icon_text $v right2
	
	set v [ go_left $v ]
	set v [ go_down $v ]
	check_icon_text $v down
	
	set v [ go_up $v ]
	set v [ go_up $v ]
	set v [ go_up $v ]	
	check_icon_text $v up


	#cross
	set diagram_id [ load_normal_db cross ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id up ]
	
	set v [ go_down $v ]
	set v [ go_right $v ]
	set v [ go_down $v ]	
	set v [ go_right $v ]	
	check_icon_text $v right


	set v [ go_left $v ]
	set v [ go_down $v ]	
	set v [ go_left $v ]	
	set v [ go_down $v ]	
	check_icon_text $v down	

	set v [ go_up $v ]
	set v [ go_left $v ]
	set v [ go_up $v ]
	set v [ go_left $v ]	
	check_icon_text $v left
	
	set v [ go_right $v ]
	set v [ go_up $v ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	check_icon_text $v up

	#cross, second pass
	set v [ go_down $v ]
	set v [ go_left $v ]
	set v [ go_down $v ]	
	set v [ go_left $v ]	
	check_icon_text $v left


	set v [ go_right $v ]
	set v [ go_down $v ]	
	set v [ go_right $v ]	
	set v [ go_down $v ]	
	check_icon_text $v down	

	set v [ go_up $v ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	set v [ go_right $v ]	
	check_icon_text $v right
	
	set v [ go_left $v ]
	set v [ go_up $v ]
	set v [ go_left $v ]
	set v [ go_up $v ]
	check_icon_text $v up
	
	#twins
	set diagram_id [ load_normal_db twins ]
	check_integrity $diagram_id

	set v [ find_icon $diagram_id red ]
	
	set v [ go_down $v ]
	set v [ go_down $v ]
	check_icon_text $v blue
	
	set v [ go_down $v ]
	set v [ go_down $v ]
	check_icon_text $v white
	
	set v [ go_up $v ]
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v black
	
	set v [ go_up $v ]
	set v [ go_up $v ]
	check_icon_text $v yellow
	
	set v [ go_up $v ]
	set v [ go_up $v ]
	check_icon_text $v green
	
	set v [ go_down $v ]
	set v [ go_left $v ]
	set v [ go_up $v ]
	check_icon_text $v red



	expect_errors bad_arrow 1
	
	
	# cross
	set diagram_id [ load_normal_db X ]
	check_integrity $diagram_id
	
	set v [ find_icon $diagram_id up ]
	
	set v [ go_down $v ]
	set v [ go_right $v ]
	check_icon_text $v right
	
	set v [ go_left $v ]
	set v [ go_down $v ]
	check_icon_text $v down
	
	set v [ go_up $v ]
	set v [ go_left $v ]
	check_icon_text $v left
	
	set v [ go_right $v ]
	set v [ go_up $v ]
	check_icon_text $v up
	
	# if
	set diagram_id [ load_normal_db if ]
	check_integrity $diagram_id
	
	set v [ find_icon $diagram_id if ]
	set if_icon [ go_down $v ]
	check_icon_text $if_icon if_icon
	
	set v [ go_down $if_icon ]
	check_icon_text $v action1

	set v [ go_down $v ]
	set v [ go_down $v ]
	check_icon_text $v End

	set v [ go_right $if_icon ]
	set v [ go_down $v ]
	check_icon_text $v action2

	set v [ go_down $v ]
	set v [ go_left $v ]
	set v [ go_down $v ]
	check_icon_text $v End
	
	
	# cross_in_select2
	set diagram_id [ load_normal_db cross_in_select2 ]
	check_integrity $diagram_id
	
	set v [ find_icon $diagram_id if ]
	set v [ go_down $v ]
	check_icon_text $v if2

	set v [ find_icon $diagram_id if ]
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v select

	set v [ find_icon $diagram_id if2 ]
	set v [ go_right $v ]
	set v [ go_down $v ]
	check_icon_text $v case1
	
	### grid
	set diagram_id [ load_normal_db grid ]
	check_integrity $diagram_id
	set vcount [ gdb onecolumn {
		select count(*) from vertices where diagram_id = :diagram_id } ]
	set ecount [ gdb onecolumn {
		select count(*) from edges where diagram_id = :diagram_id } ]
	equal $vcount 16
	equal $ecount 24	
	###

	# crossing
	set diagram_id [ load_normal_db crossing ]
	check_integrity $diagram_id


	set v [ find_icon $diagram_id if1 ]
	
	set v [ go_right $v ]
	set v [ go_down $v ]
	set v [ go_left $v ]
	check_icon_text $v if2
	
	set v [ go_down $v ]
	set v [ go_right $v ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	set v [ go_left $v ]
	set v [ go_left $v ]
	check_icon_text $v if2

	set v [ go_down $v ]
	set v [ go_right $v ]
	set v [ go_up $v ]
	set v [ go_left $v ]
	set v [ go_up $v ]
	check_icon_text $v if1
	
	ddd close
}

proc build_d { diagram_name } {
	set diagram_id [ ddd onecolumn { 
		select diagram_id from diagrams where name = :diagram_name } ]
	if { $diagram_id == "" } {
		error "Diagram $diagram_name not found"
	}
	graph::build_graph ddd $diagram_id
	return $diagram_id
}

tproc graph_check { } {
	sqlite3 ddd ../testdata/tjoins.drn
	
	build_d up
	equal [ gdb onecolumn { select count(*) from errors } ] 0
	
	build_d good
	equal [ gdb onecolumn { select count(*) from errors } ] 0
	
	build_d dangling_left
	equal [ gdb onecolumn { select count(*) from errors } ] 1

	build_d dangling_right
	equal [ gdb onecolumn { select count(*) from errors } ] 1

	build_d dangling_up
	equal [ gdb onecolumn { select count(*) from errors } ] 1

	build_d dangling_down
	equal [ gdb onecolumn { select count(*) from errors } ] 1

	build_d out_of_line
	equal [ gdb onecolumn { select count(*) from errors } ] 1

	build_d out_of_line_hor
	equal [ gdb onecolumn { select count(*) from errors } ] 1
	
	build_d disjoint
	equal [ gdb onecolumn { select count(*) from errors } ] 1
	
	ddd close
}
