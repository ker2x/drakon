namespace eval nsorter {

set stage "not initialized"
set db "<bad db>"
set start_node ""
set incoming {}

set init_sql {
	create table nodes
	(
		node_id text primary key,
		incoming integer,
		visited integer
	);

	create table links
	(
		link_id integer primary key,
		src text,
		ordinal integer,
		dst text,
		backward integer
	);

	create unique index link_by_src_ord on links(src, ordinal);
}

# Autogenerated with DRAKON Editor 1.10

proc add_incoming { node_id } {
    #item 67
    variable db
    #item 68
    $db eval {
    	update nodes
    	set incoming = incoming + 1
    	where node_id = :node_id
    }
}

proc add_link { src ordinal dst } {
    #item 101
    variable db
    variable stage
    #item 98
    if {$stage == "filling"} {
        #item 105
        ensure_node_exists $src
        ensure_node_exists $dst
        #item 104
        $db eval {
        	insert into links (src, ordinal, dst, backward)
        	values (:src, :ordinal, :dst, 0)
        }
    } else {
        #item 102
        error "Cannot add any links now."
    }
}

proc add_node { node_id } {
    #item 90
    variable db
    variable stage
    #item 87
    if {$stage == "filling"} {
        #item 93
        $db eval {
        	insert into nodes (node_id, incoming)
        	values (:node_id, 0);
        }
    } else {
        #item 91
        error "Cannot add any nodes now."
    }
}

proc clear_graph { } {
    #item 312
    variable db
    #item 313
    $db eval {
    	delete from links;
    	delete from nodes;
    }
}

proc clear_visited { } {
    #item 175
    variable db
    #item 176
    $db eval {
    	update nodes
    	set visited = 0
    }
}

proc complete_construction { } {
    #item 111
    variable db
    variable stage
    #item 110
    if {$stage == "filling"} {
        #item 115
        set stage constructed
        #item 116
        set links [ $db eval {
        	select link_id from links } ]
        #item 1180001
        set _col118 $links
        set _len118 [ llength $_col118 ]
        set _ind118 0
        while { 1 } {
            #item 1180002
            if {$_ind118 < $_len118} {
                #item 1180004
                set link_id [ lindex $_col118 $_ind118 ]
                #item 119
                set dst [ get_link_dst $link_id ]
                add_incoming $dst
                #item 1180003
                incr _ind118
                continue
            } else {
                break
            }
        }
    } else {
        #item 112
        error "Cannot complete construction now."
    }
}

proc ensure_node_exists { node_id } {
    #item 321
    variable db
    #item 34
    set count [ $db onecolumn {
    	select count(*)
    	from nodes
    	where node_id = :node_id } ]
    #item 36
    if {$count == 0} {
        #item 37
        error "Node $node_id not found."
    } else {
        
    }
}

proc find_backward_links { } {
    #item 180
    variable start_node
    #item 181
    clear_visited
    set before {}
    #item 333
    remember_incoming
    #item 182
    find_backward_recursive $start_node $before
}

proc find_backward_recursive { node_id before } {
    #item 203
    if {[ is_visited $node_id ]} {
        
    } else {
        #item 205
        mark_visited $node_id
        #item 206
        set links [ get_node_links $node_id ]
        #item 238
        set new_before [ linsert $before end $node_id ]
        #item 2340001
        set _col234 $links
        set _len234 [ llength $_col234 ]
        set _ind234 0
        while { 1 } {
            #item 2340002
            if {$_ind234 < $_len234} {
                #item 2340004
                set link_id [ lindex $_col234 $_ind234 ]
                #item 235
                set dst [ get_link_dst $link_id ]
                #item 236
                if {[ contains $new_before $dst ]} {
                    #item 237
                    mark_link_backward $link_id
                    #item 243
                    remove_incoming $dst
                } else {
                    #item 239
                    find_backward_recursive $dst $new_before
                }
                #item 2340003
                incr _ind234
                continue
            } else {
                break
            }
        }
    }
}

proc get_backward_links { } {
    #item 231
    variable db
    #item 232
    return [ $db eval {
    	select link_id
    	from links
    	where backward = 1
     } ]
}

proc get_incoming { node_id } {
    #item 275
    variable db
    #item 276
    return [ $db onecolumn {
    	select incoming
    	from nodes
    	where node_id = :node_id
    } ]
}

proc get_incoming_for_nodes { } {
    #item 337
    variable incoming
    return $incoming
}

proc get_link_dst { link_id } {
    #item 74
    variable db
    #item 75
    return [ $db onecolumn {
    	select dst
    	from links
    	where link_id = :link_id } ]
}

proc get_node_links { node_id } {
    #item 212
    variable db
    #item 213
    return [ $db eval {
    	select link_id
    	from links
    	where src = :node_id
    	order by ordinal
    } ]
}

proc get_unique_incoming { node_id } {
    #item 343
    variable db
    #item 344
    set sources [ $db eval {
    	select src
    	from links
    	where dst = :node_id
    	group by src
    } ]
    #item 345
    return [ llength $sources ]
}

proc init { dbname start_node_id } {
    #item 126
    variable stage
    variable init_sql
    variable db
    variable start_node
    #item 123
    catch { $dbname close }
    sqlite3 $dbname :memory:
    $dbname eval $init_sql
    #item 127
    set stage filling
    set db $dbname
    set start_node $start_node_id
}

proc is_link_backward { link_id } {
    #item 294
    variable db
    #item 295
    return [ $db onecolumn {
    	select backward
    	from links
    	where link_id = :link_id
    } ]
}

proc is_visited { node_id } {
    #item 193
    variable db
    #item 194
    set visited [ $db onecolumn {
    	select visited
    	from nodes
    	where node_id = :node_id
    } ]
    #item 202
    return $visited
}

proc mark_link_backward { link_id } {
    #item 219
    variable db
    #item 220
    $db eval {
    	update links
    	set backward = 1
    	where link_id = :link_id
    }
}

proc mark_visited { node_id } {
    #item 200
    variable db
    #item 201
    $db eval {
    	update nodes
    	set visited = 1
    	where node_id = :node_id
    }
}

proc pop { stack } {
    #item 263
    upvar 1 $stack collection
    #item 262
    set length [ llength $collection ]
    #item 261
    if {$length == 0} {
        #item 265
        set result ""
    } else {
        #item 267
        set result [ lindex $collection end ]
        #item 266
        set collection [ lrange $collection 0 end-1 ]
    }
    #item 269
    return $result
}

proc push { stack value } {
    #item 254
    upvar 1 $stack collection
    #item 255
    lappend collection $value
}

proc remember_incoming { } {
    #item 327
    variable db
    variable incoming
    #item 328
    set nodes [ $db eval {
    	select node_id from nodes
    } ]
    #item 3290001
    set _col329 $nodes
    set _len329 [ llength $_col329 ]
    set _ind329 0
    while { 1 } {
        #item 3290002
        if {$_ind329 < $_len329} {
            #item 3290004
            set node_id [ lindex $_col329 $_ind329 ]
            #item 330
            set incoming_links [ get_unique_incoming $node_id ]
            #item 331
            lappend incoming $node_id $incoming_links
            #item 3290003
            incr _ind329
            continue
        } else {
            break
        }
    }
}

proc remove_incoming { node_id } {
    #item 226
    variable db
    #item 227
    $db eval {
    	update nodes
    	set incoming = incoming - 1
    	where node_id = :node_id
    }
}

proc set_node_left_outgoing { node_id left_outgoing } {
    #item 158
    variable db
    #item 159
    $db eval {
    update nodes
    set left_outgoing = :left_outgoing
    where node_id = :node_id }
}

proc sort { } {
    #item 244
    variable stage
    variable start_node
    #item 316
    set result {}
    #item 246
    if {$stage == "constructed"} {
        #item 323
        find_backward_links
        #item 277
        set stack [ list $start_node ]
        add_incoming $start_node
        while { 1 } {
            #item 279
            set current [ pop stack ]
            #item 281
            remove_incoming $current
            #item 282
            if {[ get_incoming $current ] == 0} {
                #item 303
                lappend result $current
                #item 280
                set links [ get_node_links $current ]
                #item 2880001
                set _col288 $links
                set _len288 [ llength $_col288 ]
                set _ind288 0
                while { 1 } {
                    #item 2880002
                    if {$_ind288 < $_len288} {
                        #item 2880004
                        set link_id [ lindex $_col288 $_ind288 ]
                        #item 296
                        if {[ is_link_backward $link_id ]} {
                            
                        } else {
                            #item 297
                            set next [ get_link_dst $link_id ]
                            push stack $next
                        }
                        #item 2880003
                        incr _ind288
                        continue
                    } else {
                        break
                    }
                }
            } else {
                
            }
            #item 278
            if {[ llength $stack ] == 0} {
                break
            } else {
                continue
            }
        }
    } else {
        #item 247
        error "Cannot sort now."
    }
    #item 314
    clear_graph
    set stage finished
    #item 306
    return $result
}

}
