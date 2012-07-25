tproc nogoto_test { } {

	# Simple
	
	nogotot::Empty
	equal [ nogotot::One 1 ] 2
	equal [ nogotot::Two 1 ] 3
	equal [ nogotot::Three 1 ] 13
	
	# Logic
	
	equal [ nogotot::AND 0 0 ] 0
	equal [ nogotot::AND 0 1 ] 0
	equal [ nogotot::AND 1 0 ] 0
	equal [ nogotot::AND 1 1 ] 1


	equal [ nogotot::AND_NOT 0 0 ] 0
	equal [ nogotot::AND_NOT 0 1 ] 0
	equal [ nogotot::AND_NOT 1 0 ] 1
	equal [ nogotot::AND_NOT 1 1 ] 0

	equal [ nogotot::OR 0 0 ] 0
	equal [ nogotot::OR 0 1 ] 1
	equal [ nogotot::OR 1 0 ] 1
	equal [ nogotot::OR 1 1 ] 1


	equal [ nogotot::OR_NOT 0 0 ] 1
	equal [ nogotot::OR_NOT 0 1 ] 0
	equal [ nogotot::OR_NOT 1 0 ] 1
	equal [ nogotot::OR_NOT 1 1 ] 1
	
	equal [ nogotot::ComplexLogic 0 0 0 0 0 0 ] 0
	equal [ nogotot::ComplexLogic 1 1 1 1 1 1 ] 0
	
	equal [ nogotot::ComplexLogic 0 0 0 1 0 1 ] 1
	equal [ nogotot::ComplexLogic 1 0 1 0 0 0 ] 1

	
	# If
	
	equal [ nogotot::DiagonalIf 0 0 1 ] 2
	equal [ nogotot::DiagonalIf 0 1 1 ] 1001
	equal [ nogotot::DiagonalIf 1 0 1 ] 2
	equal [ nogotot::DiagonalIf 1 1 1 ] 2	
	
	equal [ nogotot::DiagonalIf2 0 0 0 1 ] 11
	equal [ nogotot::DiagonalIf2 0 0 1 1 ] 2
	equal [ nogotot::DiagonalIf2 0 1 0 1 ] 1001
	equal [ nogotot::DiagonalIf2 0 1 1 1 ] 1001
	equal [ nogotot::DiagonalIf2 1 0 0 1 ] 11
	equal [ nogotot::DiagonalIf2 1 0 1 1 ] 2
	equal [ nogotot::DiagonalIf2 1 1 0 1 ] 11
	equal [ nogotot::DiagonalIf2 1 1 1 1 ] 2

	equal [ nogotot::Diamond 0 1 ] 0
	equal [ nogotot::Diamond 1 1 ] 2
	
	equal [ nogotot::EmptyIf 0 1 ] 1
	equal [ nogotot::EmptyIf 1 1 ] 1
	
	equal [ nogotot::NestedDiamond 100 1 ] 2
	equal [ nogotot::NestedDiamond 0 1 ] 1101
	equal [ nogotot::NestedDiamond -100 1 ] 1011

	equal [ nogotot::NestedIf 100 1 ] 2
	equal [ nogotot::NestedIf 0 1 ] 101
	equal [ nogotot::NestedIf -100 1 ] 11

	equal [ nogotot::NestedIf2 100 1 ] 2
	equal [ nogotot::NestedIf2 0 1 ] 101
	equal [ nogotot::NestedIf2 -15 1 ] 11
	equal [ nogotot::NestedIf2 -100 1 ] 1001
	
	# Switch
	
	equal [ nogotot::ProcInSelect  5 ] 1
	equal [ nogotot::ProcInSelect 10 ] 2
	equal [ nogotot::ProcInSelect 30 ] 3
	
	equal [ nogotot::VarInSelect  5 ] 1
	equal [ nogotot::VarInSelect 10 ] 2
	equal [ nogotot::VarInSelect 30 ] 3
	

	# Loops
	
	equal [ nogotot::CheckDo ] 10
	equal [ nogotot::Continue ] 5
	equal [ nogotot::DoCheck ] 10
	equal [ nogotot::DoCheckDo ] 11
	equal [ nogotot::ForEach ] 4
	equal [ nogotot::ForEachBreak ] 3
	equal [ nogotot::NestedLoop ] 55
	equal [ nogotot::SimpleLoop ] 10
	equal [ nogotot::TwoBreaks ] 8
	equal [ nogotot::ThreeBreaks ] 5
	
	# Hybrid
	
	equal [ nogotot::IfInsideLoop ] 506
	equal [ nogotot::JumpFromThen ] 6
	equal [ nogotot::LoopInsideIf 1 ] 1
	equal [ nogotot::LoopInsideIf 0 ] 1100
	
	# Goto
	
	equal [ nogotot::DifferentLoopStarts ] 2
	equal [ nogotot::ExitToAbove ] 4
	
	equal [ nogotot::JumpToThen 0 0 ] 0
	equal [ nogotot::JumpToThen 0 1 ] 0
	equal [ nogotot::JumpToThen 1 0 ] 10
	equal [ nogotot::JumpToThen 1 1 ] 10
}


tproc tree_append_test { } {
	generate_structure tar {tree position}
	
	set empty [ nogoto::create_seq ]
	unpack [ nogoto::tree_append $empty {} 10 ] e2 pos
	equal $pos 1
	list_equal $e2 {seq 10}
	unpack [ nogoto::tree_append $e2 {} 20 ] e3 pos
	equal $pos 2
	list_equal $e3 {seq 10 20}
	set ifn [ nogoto::create_if 30 ]
	unpack [ nogoto::tree_append $e3 {} $ifn ] e4 pos
	equal $pos 3
	unpack [ nogoto::tree_append $e4 {} 40 ] e5 pos
	equal $pos 4
	equal $e5 {seq 10 20 {if 30 seq seq} 40}
	unpack [ nogoto::tree_append $e5 {3 2} 50] e6 pos
	equal $pos 1
	unpack [ nogoto::tree_append $e6 {3 2} 60] e6 pos
	equal $pos 2
	unpack [ nogoto::tree_append $e6 {3 3} 70] e6 pos
	equal $pos 1
	equal $e6 {seq 10 20 {if 30 {seq 50 60} {seq 70}} 40}
	set ifn2 [ nogoto::create_if 80 ]
	unpack [ nogoto::tree_append $e6 {3 2} $ifn2 ] e7 pos
	equal $pos 3
	unpack [ nogoto::tree_append $e7 {3 2 3 2} 90 ] e7 pos
	equal $pos 1
	equal $e7 {seq 10 20 {if 30 {seq 50 60 {if 80 {seq 90} seq}} {seq 70}} 40}
	
}

tproc merge_stacks_test { } {
	unpack [ nogoto::merge_stacks {} {} ] stack inter
	equal $stack ""
	equal $inter ""
	
	unpack [ nogoto::merge_stacks {a b} {} ] stack inter
	equal $stack {a b}
	equal $inter ""

	unpack [ nogoto::merge_stacks {} {c d} ] stack inter
	equal $stack {c d}
	equal $inter ""

	unpack [ nogoto::merge_stacks {a b} {c d} ] stack inter
	equal $stack {a b c d}
	equal $inter ""

	unpack [ nogoto::merge_stacks {a b} {b c} ] stack inter
	equal $stack {a b c}
	equal $inter b

	unpack [ nogoto::merge_stacks {a b c d} {f b c u} ] stack inter
	equal $stack {a b c d f u}
	equal $inter {b c}
}

tproc noggen_test {} {
	set db nogoto-db

if { 1 } {
}
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	equal [nogoto::generate $db 9] {seq 9}
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 action {}
		nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_node $db 11 action {}
		nogoto::insert_link $db 10 0 11 normal
	equal [nogoto::generate $db 9] {seq 9 10 11}


	#     9
	# 10	  11
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 action {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 11 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 11 0 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10} {seq 11}} 12}

	#     9
	# 10	  |
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 12 normal
	nogoto::insert_link $db 10 0 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10} seq} 12}

	#     9
	# |		  |
	#     12
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 12 action {}
	
	nogoto::insert_link $db 9 0 12 normal
	nogoto::insert_link $db 9 1 12 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 seq seq} 12}

	#	  8
	#     9
	# 10	  11
	#     12
	#     13
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	
	nogoto::insert_link $db 8 0 9 normal
	nogoto::insert_link $db 9 0 10 normal
	nogoto::insert_link $db 9 1 11 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 13 normal
	
	equal [nogoto::generate $db 8] {seq 8 {if 9 {seq 10} {seq 11}} 12 13}
	
	# 9
	# 10-----
	# |		11---
	# 12	13	14
	# |		-----
	# |		15
	# -------
	# 16
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 10 1 11 normal
	nogoto::insert_link $db 12 0 16 normal
	nogoto::insert_link $db 11 0 13 normal
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 15 0 16 normal
	nogoto::insert_link $db 11 1 14 normal
	nogoto::insert_link $db 14 0 15 normal
	equal [nogoto::generate $db 9] {seq 9 {if 10 {seq 12} {seq {if 11 {seq 13} {seq 14}} 15}} 16}
	
	# 9
	# |
	# 10---------
	# |			|
	# 12---		11---
	# |	  |		|	|
	# 17  18	13	14
	# |	  |		|	|	
	# |----		-----
	# |			|
	# -----------
	# |
	# 16
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 16 action {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 10 1 11 normal
	
	nogoto::insert_link $db 12 0 17 normal
	nogoto::insert_link $db 12 1 18 normal
	nogoto::insert_link $db 17 0 16 normal
	nogoto::insert_link $db 18 0 16 normal
	
	nogoto::insert_link $db 11 0 13 normal
	nogoto::insert_link $db 11 1 14 normal	
	nogoto::insert_link $db 13 0 16 normal
	nogoto::insert_link $db 14 0 16 normal
	
	equal [nogoto::generate $db 9] {seq 9 {if 10 {seq {if 12 {seq 17} {seq 18}}} {seq {if 11 {seq 13} {seq 14}}}} 16}
	
	
	# 9----
	# |	   |
	# 10---|
	# |	   |	
	# 11---|
	# |	   |	
	# 12   13
	# |	   |	
	# ------
	# |	
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 13 normal

	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 13 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 13 0 14 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq {if 11 {seq 12} {seq 13}}} {seq 13}}} {seq 13}} 14}


	# 9---------
	# |	   		|
	# 10---|	|
	# |	   |	|
	# 11---|	|
	# |	   |	|
	# 12   13	|
	# |	   |	|	
	# ----------
	# |	
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 14 normal

	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 13 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 13 0 14 normal
	
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq {if 11 {seq 12} {seq 13}}} {seq 13}}} seq} 14}


	
	# 9-----
	# |     |
	# 10	11---
	# |     |	 |
	# |-----	 |
	# 12		 13
	# |			 |
	# |----------
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 10 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 13 normal
	
	nogoto::insert_link $db 13 0 14 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq 10 12} {seq {if 11 {seq 12} {seq 13}}}} 14}

	# 9---------
	# |			|
	# 10----	|
	# |		|	|
	# |		11--
	# |		|	|
	# 14	 ---12
	# |			|
	# |---------
	# |
	# 13
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}

	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 12 normal
	
	nogoto::insert_link $db 10 0 14 normal
	nogoto::insert_link $db 10 1 11 normal

	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 12 normal
	
	nogoto::insert_link $db 14 0 13 normal
	nogoto::insert_link $db 12 0 13 normal
	
	equal [nogoto::generate $db 9] {seq {if 9 {seq {if 10 {seq 14} {seq {if 11 seq seq} 12}}} {seq 12}} 13}



	# |
	# 9-----
	# |		|
	# |		|		
	# |		16--
	# 13----|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# |		|		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			

	nogoto::create_db $db

	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 16 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 17 normal

	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 9 ] {seq {if 9 {seq {if 13 seq {seq 17 12}}} {seq {if 16 {seq 17} {seq 18}} 12}} 15}


	# |
	# 9-----
	# |		|
	# 10	11-- 	
	# |		|	|	
	# |-----	|	
	# |			|	
	# 12----	|		
	# |		|	|		
	# |		13	|
	# |		|	|
	# |-----	|	
	# |			|	
	# 14		|
	# |			|
	# |---------
	# 15

	nogoto::create_db $db

	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 10 0 12 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 15 normal

	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 12 1 13 normal
	
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db 14 0 15 normal

	equal [ nogoto::generate $db 9 ] {seq {if 9 {seq 10 {if 12 seq {seq 13}} 14} {seq {if 11 {seq {if 12 seq {seq 13}} 14} seq}}} 15}



	# 8
	# |
	# |<----
	# |		|
	# 9-----
	# |
	# 10
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}

	nogoto::insert_link $db  8 0 9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 9 normal
	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} {seq continue}}} 10}


	# 260
	# |
	# |   
	# |	 
	# 262--- 
	# |		|
	# |		|<------
	# |		| 		|
	# |		|		|
	# |		263-	|
	# |		|	|	|
	# |-----	264	|
	# |			|	|
	# |			----
	# |
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 264 action {}
	nogoto::insert_node $db 259 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  264	0	263	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal
		

	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} {seq 264 continue}}}} seq} 259 256}


	# 8
	# |
	# |<---------
	# |			|
	# |			|
	# 9-----	|
	# |		|	|
	# |		|	|
	# |		|	|	
	# |		11--
	# |		|
	# |		|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0  9 normal
#	nogoto::insert_link $db 10 0  9 normal
	
	nogoto::insert_link $db  9 0 14 normal
	nogoto::insert_link $db  9 1 11 normal	
	
#	nogoto::insert_link $db 12 0 11 normal


	nogoto::insert_link $db 11 0 14 normal
	nogoto::insert_link $db 11 1  9 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} {seq {if 11 {seq break} {seq continue}}}}} 14}


	# 179
	# |
	# |<------------
	# |				|
	# |				|	
	# 1802---		|
	# |		|		|
	# |		1804	|	
	# |		184-	| x
	# |		|	|	|
	# |		|	182	|
	# |-----	|	|
	# |			 ---
	# 183
	
	nogoto::create_db $db
	nogoto::insert_node $db 179 action {}	
	nogoto::insert_node $db 1800002 if {}	
	nogoto::insert_node $db 183 action {}	
	nogoto::insert_node $db 1800004 action {}	
	nogoto::insert_node $db 184 if {}	
	nogoto::insert_node $db 182 action {}
	
	nogoto::insert_link $db 179 0 1800002 normal
	nogoto::insert_link $db 1800002 0 183 normal
	nogoto::insert_link $db 1800002 1 1800004 normal
	nogoto::insert_link $db 1800004 0 184 normal
	nogoto::insert_link $db 184 0 182 normal
	nogoto::insert_link $db 184 1 183 normal
	nogoto::insert_link $db 182 0 1800002 normal
	
	equal [ nogoto::generate $db 179 ] {seq 179 {loop {if 1800002 {seq break} {seq 1800004 {if 184 {seq 182 continue} {seq break}}}}} 183}

	# 190
	# |
	# |<---------
	# |			|
	# 196		|
	# |			|	
	# 191---	|
	# |		|	|
	# |		195	|
	# |		|	|	
	# |		198-
	# |		|
	# |		|	
	# |-----
	# |
	# 193
	# |

	
	
	
	nogoto::create_db $db
	nogoto::insert_node $db 190	action	{}
	nogoto::insert_node $db 191	if	{}
	nogoto::insert_node $db 193	action	{}
	nogoto::insert_node $db 195	action	{}
	nogoto::insert_node $db 196	action	{}
	nogoto::insert_node $db 198	if	{}
	
	nogoto::insert_link $db 190	0	196	normal
	nogoto::insert_link $db 196	0	191	normal
	nogoto::insert_link $db 191	0	193	normal
	nogoto::insert_link $db 191	1	195	normal
	nogoto::insert_link $db 195	0	198	normal
	nogoto::insert_link $db 198	0	193	normal
	nogoto::insert_link $db 198	1	196	normal
	


	equal [ nogoto::generate $db 190 ] {seq 190 {loop 196 {if 191 {seq break} {seq 195 {if 198 {seq break} {seq continue}}}}} 193}


	# 260
	# |
	# |   
	# |	 
	# 262--- 
	# |		|
	# |		|<----------
	# |		| 			|
	# |		|			|
	# |		263-		|
	# |		|	|		|
	# |-----	264-	|
	# |			|	|	|
	# |			270	271	|
	# |			|	|	|
	# |			|---	|
	# |			|		|
	# |			--------
	# |
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 259 action {}
	
	nogoto::insert_node $db 264 if {}
	nogoto::insert_node $db 270 action {}
	nogoto::insert_node $db 271 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_link $db  264	0	270	normal
	nogoto::insert_link $db  264	1	271	normal
	nogoto::insert_link $db  270	0	263	normal
	nogoto::insert_link $db  271	0	263	normal
	
	

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal

	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} {seq {if 264 {seq 270 continue} {seq 271 continue}}}}}} seq} 259 256}


	# 260
	# |
	# |   
	# |	 
	# 262--- 
	# |		|
	# |		|<----------
	# |		| 			|
	# |		|			|
	# |		263-		|
	# |		|	|		|
	# |-----	264-	|
	# |			|	|	|
	# |			270	271	|
	# |			|	|	|
	# |			|---	|
	# |			272		|
	# |			|		|
	# |			--------
	# |
	# 259
	# |
	# 256
	nogoto::create_db $db
	nogoto::insert_node $db 260 action {}
	nogoto::insert_node $db 262 if {}
	nogoto::insert_node $db 263 if {}
	nogoto::insert_node $db 259 action {}
	
	nogoto::insert_node $db 264 if {}
	nogoto::insert_node $db 270 action {}
	nogoto::insert_node $db 271 action {}
	nogoto::insert_node $db 272 action {}
	


	nogoto::insert_link $db  260	0	262	normal
	nogoto::insert_link $db  262	0	263	normal
	nogoto::insert_link $db  263	0	259	normal
	nogoto::insert_link $db  263	1	264	normal
	nogoto::insert_link $db  272	0	263	normal
	nogoto::insert_link $db  262	1	259	normal

	nogoto::insert_link $db  264	0	270	normal
	nogoto::insert_link $db  264	1	271	normal
	nogoto::insert_link $db  270	0	272	normal
	nogoto::insert_link $db  271	0	272	normal
	
	

	nogoto::insert_node $db 256 action {}		
	nogoto::insert_link $db  259	0	256	normal
	
	equal [ nogoto::generate $db 260 ] {seq 260 {if 262 {seq {loop {if 263 {seq break} {seq {if 264 {seq 270} {seq 271}} 272 continue}}}} seq} 259 256}

	
	# 8
	# |
	# |<---------
	# |			|
	# 10		|	
	# |			|
	# 9-----	|
	# |		|	|
	# |		11--
	# |		|
	# 13	12
	# |		|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq 13 break} {seq {if 11 {seq 12 break} {seq continue}}}}} 14}


	
	# 8
	# |
	# |<---------
	# |			|
	# 10		|	
	# |			|
	# 9-----	|
	# |		|	|
	# 15-	11--
	# |	 |	|   |
	# 13 16	12--
	# |	 |	|	
	# |-----
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 if {}
	nogoto::insert_node $db 16 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal
	
	nogoto::insert_link $db 15 0 13 normal
	nogoto::insert_link $db 15 1 16 normal
	nogoto::insert_link $db 16 0 14 normal
	nogoto::insert_link $db 12 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 15 {seq 13 break} {seq 16 break}}} {seq {if 11 {seq {if 12 {seq break} {seq continue}}} {seq continue}}}}} 14}


	# 8---------
	# |			|
	# |<----	|
	# |		|	|
	# 9-----	|
	# |---------
	# 10
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}

	nogoto::insert_link $db  8 0 9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 9 normal
	nogoto::insert_link $db  8 1 10 normal
	

	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop {if 9 {seq break} {seq continue}}}} seq} 10}	

	# |
	# 8-------------
	# |				|
	# |<---------	|
	# |			|	|
	# 10		|	|
	# |			|	|
	# 9-----	|	|
	# |		|	|	|
	# |		11--	|
	# |		|		|
	# 13	12		|
	# |		|		|
	# |-----		|
	# |-------------
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 14 normal
	nogoto::insert_link $db 11 1 10 normal
	nogoto::insert_link $db  8 1 14 normal

	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop 10 {if 9 {seq 13 break} {seq {if 11 {seq 12 break} {seq continue}}}}}} seq} 14}


	# 8
	# |
	# |<----------
	# |			  |
	# 9---------  |
	# |			| |
	# |<---		| |
	# |    |	| |
	# 10---		| |
	# |		  	| |
	# |---------  |
	# |			  |
	# 11----------
	# |
	# 12
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}

	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1 10 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1  9 normal
	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq {loop {if 10 {seq break} {seq continue}}}} seq} {if 11 {seq break} {seq continue}}} 12}

	
	# |
	# 8-------------
	# |				|
	# |<---------	|
	# |			|	|
	# 10		|	|
	# |			|	|
	# 9-----	|	|
	# |		|	|	|
	# |		11--	|
	# |		|		|
	# 13----		|
	# |		|		|	
	# |		12		|
	# |		|		|
	# |-----		|
	# |				|
	# 15			|
	# |				|	
	# |-------------
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 if {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 14 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 12 normal
	nogoto::insert_link $db 15 0 14 normal
	nogoto::insert_link $db  9 1 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 11 1 10 normal
	nogoto::insert_link $db  8 1 14 normal


	equal [ nogoto::generate $db 8 ] {seq {if 8 {seq {loop 10 {if 9 {seq {if 13 {seq break} {seq 12 break}}} {seq {if 11 {seq 12 break} {seq continue}}}}} 15} seq} 14}
	

	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------| x
	# |		|		
	# |		16--
	# |		|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# 13----		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 12 normal

	nogoto::insert_link $db 11 1 16 normal
	nogoto::insert_link $db 11 0 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 13 {seq break} {seq 12 break}}} {seq {if 11 {seq continue} {seq {if 16 {seq 17} {seq 18}} 12 break}}}}} 15}
	
	
	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------| x
	# |		|		
	# |		16--
	# 13----|	|	
	# |		17  18	
	# |		|	|	
	# |		|---	
	# |		|		
	# |		|		
	# |		|			
	# |		12
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 15 action {}
	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 action {}

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal
	nogoto::insert_link $db 13 1 17 normal

	nogoto::insert_link $db 11 1 16 normal
	nogoto::insert_link $db 11 0 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	
	nogoto::insert_link $db 12 0 15 normal


	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq {if 13 {seq break} {seq 17 12 break}}} {seq {if 11 {seq continue} {seq {if 16 {seq 17} {seq 18}} 12 break}}}}} 15}


	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 9-----		|
	# |		|		|
	# |		16--	|
	# |		|	|	|
	# |		|	18--|
	# |		|	|	|
	# |		|---	|	
	# |		|		|	
	# |		12------|
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_node $db 16 if {}	
	nogoto::insert_node $db 18 if {}
	

	nogoto::insert_link $db  8 0  9 normal
	
	
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db  9 1 16 normal
	


	
	nogoto::insert_link $db 16 0 12 normal
	nogoto::insert_link $db 16 1 18 normal


	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 18 1  9 normal
	
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1  9 normal	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} {seq {if 16 seq {seq {if 18 seq {seq continue}}}} {if 12 {seq break} {seq continue}}}}} 15}

	
	



	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 10			|
	# |				|
	# 9-----		|
	# |		|		|
	# |		11------|
	# |		|		|
	# |		16--	|
	# |		|	|	|
	# |		17	18--|
	# |		|	|	|
	# |		|---	|	
	# 13	|		|
	# |		|		|	
	# |		12------|
	# |		|	
	# |-----		
	# |				
	# 15			
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}
	nogoto::insert_node $db 13 action {}
	nogoto::insert_node $db 15 action {}

	nogoto::insert_node $db 16 if {}
	nogoto::insert_node $db 17 action {}
	nogoto::insert_node $db 18 if {}
	

	nogoto::insert_link $db  8 0 10 normal
	nogoto::insert_link $db 10 0  9 normal
	
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 11 normal
	
	nogoto::insert_link $db 13 0 15 normal


	nogoto::insert_link $db 11 0 16 normal
	nogoto::insert_link $db 11 1 10 normal
	
	nogoto::insert_link $db 16 0 17 normal
	nogoto::insert_link $db 16 1 18 normal
	
	nogoto::insert_link $db 17 0 12 normal
	nogoto::insert_link $db 18 0 12 normal
	nogoto::insert_link $db 18 1 10 normal
	
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1 10 normal

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 10 {if 9 {seq 13 break} {seq {if 11 {seq {if 16 {seq 17} {seq {if 18 seq {seq continue}}}} {if 12 {seq break} {seq continue}}} {seq continue}}}}} 15}


	# |
	# 8
	# |
	# |<------------|
	# |				|
	# 9				|
	# |				|
	# |<----		|
	# |		|		|
	# 10	|		|
	# |		|		|
	# 11----		|
	# |				|
	# 12			|
	# |				|
	# 13------------|
	# |	
	# |
	# |
	# 14
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 action {}
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 action {}
	nogoto::insert_node $db 13 if {}
	nogoto::insert_node $db 14 action {}
	

	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db 10 0 11 normal
	
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 10 normal

	nogoto::insert_link $db 12 0 13 normal
	
	nogoto::insert_link $db 13 0 14 normal	
	nogoto::insert_link $db 13 1  9 normal
	

	equal [ nogoto::generate $db 8 ] {seq 8 {loop 9 {loop 10 {if 11 {seq break} {seq continue}}} 12 {if 13 {seq break} {seq continue}}} 14}	

	# |
	# 8
	# |
	# |<--------------------
	# |						|
	# 9-----				|
	# |		|				|
	# |		10				|
	# |		|				|
	# |		|<----------	|
	# |		|			|	|
	# |		11------	|	|
	# |		|		|	|	|
	# |		|		12	|	|
	# |		|		|	|	|
	# |		|		 ---	|
	# |		 ---------------
	# |
	# 13
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}	
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}	
	nogoto::insert_node $db 11 if {}	
	nogoto::insert_node $db 12 action {}	
	nogoto::insert_node $db 13 action {}
	
	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 13 normal
	nogoto::insert_link $db  9 1 10 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 11 0  9 normal
	nogoto::insert_link $db 11 1 12 normal
	nogoto::insert_link $db 12 0 11 normal
	
	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} {seq 10 {loop {if 11 {seq break} {seq 12 continue}}} continue}}} 13}
	
	# |
	# 8
	# |
	# |<--------------------
	# |						|
	# 9-----				|
	# |		|				|
	# |		10				|
	# |		|				|
	# |		11----------	|	
	# |		|			|	|
	# |		12------	|	|
	# |		|		|	|	|
	# |		|		13	|	|
	# |		|		|	|	|
	# |		|		 ---	|
	# |		|			|	|
	# |		|			14	|
	# |		|			|	|	
	# |-----			----
	# |
	# 15
	
	nogoto::create_db $db
	nogoto::insert_node $db 8 action {}	
	nogoto::insert_node $db 9 if {}
	nogoto::insert_node $db 10 action {}	
	nogoto::insert_node $db 11 if {}
	nogoto::insert_node $db 12 if {}	
	nogoto::insert_node $db 13 action {}	
	nogoto::insert_node $db 14 action {}	
	nogoto::insert_node $db 15 action {}
	
	nogoto::insert_link $db  8 0  9 normal
	nogoto::insert_link $db  9 0 15 normal
	nogoto::insert_link $db  9 1 10 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 11 0 12 normal
	nogoto::insert_link $db 11 1 14 normal
	nogoto::insert_link $db 12 0 15 normal
	nogoto::insert_link $db 12 1 13 normal
	nogoto::insert_link $db 13 0 14 normal
	nogoto::insert_link $db 14 0  9 normal
	equal [ nogoto::generate $db 8 ] {seq 8 {loop {if 9 {seq break} {seq 10 {if 11 {seq {if 12 {seq break} {seq 13 14 continue}}} {seq 14 continue}}}}} 15}	
}


tproc meet_test { } {
	set db nogoto-db
	nogoto::create_db $db

	# 10--------
	# 20----   |
	# |    30---
	# |    |   |
	# |    ----40
	# |		   |
	# |---------
	
	set parents(10) [ create_parent 10 4 if {300 3} ]
	set parents(20) [ create_parent 20 3 if {300 3 4 5} ]
	set parents(30) [ create_parent 30 2 if {300 3 4 5 6 7} ]
	
	set existing {}
	set point [ create_point 40 {300 3 4 6} {10} 1]
	set existing [ nogoto::meet parents $existing $point ]
	list_equal $existing {{40 {300 3 4 6} 10 1}}

	set point [ create_point 40 {300 3 4 5 6 7 8 9} {10 20 30} 1]
	set existing [ nogoto::meet parents $existing $point ]
	list_equal $existing {
		{40 {300 3 4 6} 10 1}
		{40 {300 3 4 5 6 7 8 9} {10 20 30} 1}
	}
	
	set point [ create_point 40 {300 3 4 5 6 7 8 10} {10 20 30} 1]
	set existing [ nogoto::meet parents $existing $point ]
	list_equal $existing {
		{40 {300 3 4 6} 10 1}
		{40 {300 3 4 5 6 7} {10 20} 1}
	}
}

tproc meet_test2 { } {
	set db nogoto-db
	nogoto::create_db $db

	# 10--------
	# 20----   30---
	# |    |   |    |
	# |    |   |    |
	# |-------------
	# |
	# 40
	
	set parents(10) [ create_parent 10 4 if {50 300 3} ]
	set parents(20) [ create_parent 20 2 if {50 300 3 4 5} ]
	set parents(30) [ create_parent 30 2 if {50 300 3 4 6} ]
	set parents(5) [ create_parent 5 7 if {50} ]
	
	set existing {}
	set point1 [ create_point 40 {50 300 3 4 5 10 2} {5 10 20} 1]
	set point2 [ create_point 40 {50 300 3 4 5 10 3} {5 10 20} 1]
	set point3 [ create_point 40 {50 300 3 4 6 11 2} {5 10 30} 1]
	
	set existing [ nogoto::meet parents $existing $point1 ]
	set existing [ nogoto::meet parents $existing $point2 ]
	set existing [ nogoto::meet parents $existing $point3 ]
	list_equal $existing {
		{40 {50 300 3 4 5} {5 10} 1}
		{40 {50 300 3 4 6 11 2} {5 10 30} 1}
	}

	set point4 [ create_point 40 {50 300 3 4 6 11 3} {5 10 30} 1]
	set existing [ nogoto::meet parents $existing $point4 ]
	list_equal $existing {
		{40 {50 300 3} 5 1}
	}	
	
	equal [ get_parent_value $parents(5) ] 4
}

tproc meet_test3 { } {
	set db nogoto-db
	nogoto::create_db $db
	
	set parents(10) [ create_parent 10 4 if {50 300 3} ]
	set parents(20) [ create_parent 20 2 loop {50 300 3 4 5} ]
	set parents(30) [ create_parent 30 2 if {50 300 3 4 6} ]	
	
	set point1 [ create_point 40 {} {10 20 30} 1]
	set point2 [ create_point 40 {} {20 10 20} 1]

	set existing [ list $point1 ]
	
	equal [ nogoto::meet parents $existing $point2 ] "error"
	
}

tproc find_last_stack_loop_test { } {
	set db nogoto-db
	nogoto::create_db $db
	
	set parents(10) [ create_parent 10 4 if {50 300 3} ]
	set parents(20) [ create_parent 20 2 loop {50 300 3 4 5} ]
	set parents(30) [ create_parent 30 2 if {50 300 3 4 6} ]	

	equal [ nogoto::find_last_stack_loop parents {} ] -1
	equal [ nogoto::find_last_stack_loop parents {10 30} ] -1
	equal [ nogoto::find_last_stack_loop parents {10 20 30} ] 1
}

tproc check_loops_ok_test { } {
	nogoto::create_db foo-db
	
	set left {}
	set right {}
	set parents(1) [ create_parent 1 3 if {} ]
	set parents(2) [ create_parent 2 3 loop {} ]
	set parents(3) [ create_parent 3 3 if {} ]
	set parents(4) [ create_parent 4 3 loop {} ]
	equal [ nogoto::check_loops_ok parents $left $right ] 1
	equal [ nogoto::check_loops_ok parents {} {3} ] 1
	equal [ nogoto::check_loops_ok parents {1} {3} ] 1
	equal [ nogoto::check_loops_ok parents {1 3} {3 1} ] 1	
	equal [ nogoto::check_loops_ok parents {1 2 3 4} {1 2 3 4} ] 1
	equal [ nogoto::check_loops_ok parents {3 2 1 4} {1 2 3 4} ] 1
	equal [ nogoto::check_loops_ok parents {1 2 3} {1 2 3 4} ] 0
	equal [ nogoto::check_loops_ok parents {2 3 4} {1 2 3 4} ] 0
	equal [ nogoto::check_loops_ok parents {2 3} {1 3} ] 0
}

tproc extract_stack_loops_test {} {
	nogoto::create_db foo-db
	
	set left {}
	set right {}
	set parents(10) [ create_parent 10 3 if {} ]
	set parents(20) [ create_parent 20 3 loop {} ]
	set parents(30) [ create_parent 30 3 if {} ]
	set parents(40) [ create_parent 40 3 loop {} ]
	
	list_equal [ nogoto::extract_stack_loops parents {10 20 30 40} ] {1 20 3 40}
	list_equal [ nogoto::extract_stack_loops parents {} ] {}
	list_equal [ nogoto::extract_stack_loops parents {10 30} ] {}
}


tproc strip_loop_test { } {
	nogoto::create_db foo-db
	
	set parents(10) [ create_parent 10 3 if {} ]
	set parents(20) [ create_parent 20 3 loop {} ]
	set parents(30) [ create_parent 30 3 if {} ]
	set parents(40) [ create_parent 40 3 loop {} ]
	set parents(50) [ create_parent 50 1 if {} ]
	set parents(60) [ create_parent 60 0 loop {} ]
	set parents(70) [ create_parent 70 1 if {} ]
	set parents(80) [ create_parent 80 0 loop {} ]
	
	equal [ nogoto::strip_loop parents {60 70} ] {}
	equal [ nogoto::strip_loop parents {10 20 30 60 70} ] {10 20 30}
}

tproc try_create_point_test { } {
	set db test-db
	# |<--------
	# |			|
	# 9			|
	# |			|
	# 10--------
	# |
	# 11
	
	nogoto::create_db $db
	nogoto::insert_node $db 9 action {}
	nogoto::insert_node $db 10 if {}
	nogoto::insert_node $db 11 action {}
	
	nogoto::insert_link $db  9 0 10 normal
	nogoto::insert_link $db 10 0 11 normal
	nogoto::insert_link $db 10 1  9 normal
	
	nogoto::clear_marked $db
	nogoto::mark_backward_links $db 0 9 {}
	nogoto::insert_loops $db
	
	set tree {loop 9 {if 10 {seq break} {seq}}}
	set points {p1}
	set path {2 3}
	set stack {12 10}
	set parents(12) [ create_parent 12 1 loop {} ]
	set parents(10) [ create_parent 10 2 if {2} ]
	unpack [ nogoto::try_create_point $db parents $points $tree 10 0 $path $stack ] points tree
	equal $points {p1 {11 {2 3} {12 10} 1}}
	equal $tree {loop 9 {if 10 {seq break} {seq}}}
	
	return
	unpack [ nogoto::try_create_point $db parents $points $tree 11 0 $path $stack ] points tree
	equal $points {p1 {11 {2 3} {12 10} 1}}
	equal $tree {loop 9 {if 10 {seq break} {seq}}}
	
	unpack [ nogoto::try_create_point $db parents $points $tree 10 1 $path $stack ] points tree
	equal $points {p1 {11 {2 3} {12 10} 1}}
	equal $tree {loop 9 {if 10 {seq break} {seq continue}}}
	equal [ get_parent_value $parents(12) ] 0
	equal [ get_parent_value $parents(10) ] 1
}

tproc get_parent_break_test { } {
	set db nogoto-db
	nogoto::create_db $db
	
	set parent [ create_parent 100 2 loop {1 2 3} ]
	equal [ nogoto::get_parent_break $parent ] ""
	set parent2 [ nogoto::set_parent_break $parent 800 ]
	equal [ nogoto::get_parent_break $parent2 ] 800
}

tproc split_parents_test { } {
	set db nogoto-db
	nogoto::create_db $db

	set parents(10) [ create_parent 10 5 if {} ]
	set parents(20) [ create_parent 20 4 loop {} ]
	set parents(30) [ create_parent 30 3 if {} ]
	set parents(40) [ create_parent 40 2 if {} ]
	
	set stack {10 20 30 40}
	nogoto::split_parents parents $stack
	equal [ get_parent_value $parents(10) ] 6
	equal [ get_parent_value $parents(20) ] 4
	equal [ get_parent_value $parents(30) ] 4
	equal [ get_parent_value $parents(40) ] 3
}

tproc join_parents_test { } {
	set db nogoto-db
	nogoto::create_db $db

	set parents(10) [ create_parent 10 5 if {} ]
	set parents(20) [ create_parent 20 4 loop {} ]
	set parents(30) [ create_parent 30 3 if {} ]
	set parents(40) [ create_parent 40 2 if {} ]
	
	set stack {10 20 30 40}
	nogoto::join_parents parents $stack
	equal [ get_parent_value $parents(10) ] 4
	equal [ get_parent_value $parents(20) ] 4
	equal [ get_parent_value $parents(30) ] 2
	equal [ get_parent_value $parents(40) ] 1
}


tproc clean_stack_test { } {
	set db nogoto-db
	nogoto::create_db $db

	set parents(5) [ create_parent 5 4 if {path5} ]
	set parents(10) [ create_parent 10 3 if {path10} ]
	set parents(20) [ create_parent 20 0 loop {path20} ]
	set parents(30) [ create_parent 30 1 if {path30} ]
	set parents(40) [ create_parent 40 0 if {path40} ]
	
	set stack {5 10 30 20 40}
	set path {old_path}
	set point0 [ create_point 800 $path $stack 1 ]
	set point1 [ nogoto::clean_stack parents $point0 ]
	equal $point1 {800 path30 {5 10 20} 1}
}


proc print_nodes { db } {

	$db eval {
		select *
		from nodes
		order by item_id
	} {
		puts "$item_id:\toutgoing: $outgoing,\tincount: $incount\tstacks: $stacks"
	}
}
