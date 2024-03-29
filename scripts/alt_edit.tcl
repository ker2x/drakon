namespace eval alt {

variable hit_shadows {}

variable aligned_x {}
variable orthos_x {}
variable aligned_y {}
variable orthos_y {}

array set t_marked {}
	# 1 (scalar) for marked

array set t_shadows {}
	# 0 role
	# 1 type
	# 2 left
	# 3 top
	# 4 right
	# 5 bottom
	# 6 item_type
	# 7 item_id

array set t_items {}
	# 0 type
	# 1 inversed

array set t_item_shadows {}
	# map stored as list of keys and values: role -> shadow_id

variable next_shadow_id 0

# Autogenerated with DRAKON Editor 1.10

proc clear { } {
    #item 782
    variable t_marked
    variable t_shadows
    variable t_shadows_by_item_role
    variable t_items
    variable t_item_shadows
    #item 996
    array unset t_marked
    array unset t_shadows
    array unset t_shadows_by_item_role
    array unset t_items
    array unset t_item_shadows
    #item 781
    array set t_marked {}
    array set t_shadows {}
    array set t_shadows_by_item_role {}
    array set t_items {}
    array set t_item_shadows {}
    #item 1682
    variable next_shadow_id
    set next_shadow_id 0
}

proc clear_affected_items { } {
    #item 1659
    variable t_marked
    #item 1658
    array unset t_marked
    array set t_marked {}
}

proc delete { item_id } {
    #item 1674
    variable t_shadows
    variable t_items
    variable t_item_shadows
    #item 752
    array set shadows $t_item_shadows($item_id)
    set roles [ array names shadows ]
    #item 1676
    unset t_items($item_id)
    unset t_item_shadows($item_id)
    #item 16770001
    set _col1677 $roles
    set _len1677 [ llength $_col1677 ]
    set _ind1677 0
    while { 1 } {
        #item 16770002
        if {$_ind1677 < $_len1677} {
            #item 16770004
            set role [ lindex $_col1677 $_ind1677 ]
            #item 1773
            set shadow_id $shadows($role)
            #item 1679
            unset t_shadows($shadow_id)
            #item 16770003
            incr _ind1677
            continue
        } else {
            break
        }
    }
}

proc filter_hit { shadows x y } {
    #item 1527
    set result {}
    #item 15260001
    set _col1526 $shadows
    set _len1526 [ llength $_col1526 ]
    set _ind1526 0
    while { 1 } {
        #item 15260002
        if {$_ind1526 < $_len1526} {
            #item 15260004
            set shadow_id [ lindex $_col1526 $_ind1526 ]
            #item 1530
            set rect [ get_shadow_by_id $shadow_id ]
            #item 1531
            set cd_rect [ add_border $rect 5 ]
            #item 1532
            if {[ hit_rectangle $cd_rect $x $y ]} {
                #item 1533
                lappend result $shadow_id
            } else {
                
            }
            #item 15260003
            incr _ind1526
            continue
        } else {
            break
        }
    }
    #item 1528
    return $result
}

proc find_allied { shadow_id direction delta allied } {
    #item 1267
    upvar 1 $allied output
    #item 1268
    if {[ is_marked $shadow_id ]} {
        
    } else {
        #item 1271
        lappend output $shadow_id
        #item 1642
        mark_shadow $shadow_id
        #item 1275
        unpack [ get_shadow_by_id $shadow_id ] \
        	left top right bottom
        set type [ get_shadow_type $shadow_id ]
        set axis_or [ opposite_orientation $direction ]
        #item 1561
        set mytype [ get_shadow_type $shadow_id ]
        #item 12720001
        set _col1272 [ get_aligned $direction ]
        set _len1272 [ llength $_col1272 ]
        set _ind1272 0
        while { 1 } {
            #item 12720002
            if {$_ind1272 < $_len1272} {
                #item 12720004
                set other [ lindex $_col1272 $_ind1272 ]
                #item 1273
                if {$shadow_id == $other} {
                    
                } else {
                    #item 1277
                    set otype [ get_shadow_type $other ]
                    #item 1276
                    unpack [ get_shadow_by_id $other ] \
                    	oleft otop oright obottom
                    #item 1279
                    if {([ rectangles_on_axis $left $top $right $bottom \
	$oleft $otop $oright $obottom $axis_or ]) || ([ should_also_pull $shadow_id $mytype $other \
	$direction $delta ])} {
                        #item 1281
                        find_allied $other $direction $delta output
                    } else {
                        
                    }
                }
                #item 12720003
                incr _ind1272
                continue
            } else {
                break
            }
        }
    }
}

proc get_affected_items { } {
    #item 1767
    variable t_marked
    variable t_shadows
    #item 1768
    set shadows [ array names t_marked ]
    #item 1776
    set result {}
    #item 17780001
    set _col1778 $shadows
    set _len1778 [ llength $_col1778 ]
    set _ind1778 0
    while { 1 } {
        #item 17780002
        if {$_ind1778 < $_len1778} {
            #item 17780004
            set shadow_id [ lindex $_col1778 $_ind1778 ]
            #item 1775
            set shadow $t_shadows($shadow_id)
            set item_id [ lindex $shadow 7 ]
            #item 1780
            lappend result $item_id
            #item 17780003
            incr _ind1778
            continue
        } else {
            break
        }
    }
    #item 1777
    return $result
}

proc get_dimension { shadow_id direction } {
    #item 1761
    variable t_shadows
    #item 1762
    set shadow $t_shadows($shadow_id)
    #item 14250001
    if {$direction == "horizontal"} {
        #item 1763
        set small_index 2
        set big_index 4
    } else {
        #item 14250002
        if {$direction == "vertical"} {
            
        } else {
            #item 14250003
            error "Unexpected switch value: $direction"
        }
        #item 1764
        set small_index 3
        set big_index 5
    }
    #item 1765
    set small [ lindex $shadow $small_index ]
    set big [ lindex $shadow $big_index ]
    #item 1766
    return [ expr { $big - $small } ]
}

proc get_item { item_id } {
    #item 842
    variable t_items
    #item 858
    set item $t_items($item_id)
    set type [ lindex $item 0 ]
    set inverse [ lindex $item 1 ]
    #item 8430001
    if {$type == "horizontal"} {
        #item 857
        unpack [ get_shadow $item_id main ] x y right foo
        set w [ expr { $right - $x } ]
        set result [ list $x $y $w 0 0 0 ]
    } else {
        #item 8430002
        if {$type == "vertical"} {
            #item 884
            unpack [ get_shadow $item_id main ] x y foo bottom
            set h [ expr { $bottom - $y } ]
            set result [ list $x $y 0 $h 0 0 ]
        } else {
            #item 8430003
            if {$type == "arrow"} {
                #item 885
                unpack [ get_shadow $item_id top ] tleft ttop tright tbottom
                unpack [ get_shadow $item_id main ] mleft mtop mright mbottom
                unpack [ get_shadow $item_id bottom ] bleft btop bright bbottom
                #item 886
                set x $mleft
                set y $mtop
                set w [ expr { $tright - $tleft } ]
                set h [ expr { $mbottom - $mtop } ]
                set a [ expr { $bright - $bleft } ]
                #item 887
                set result [ list $x $y $w $h $a $inverse ]
            } else {
                #item 8430004
                if {($type == "if") || ($type == "commentout")} {
                    #item 888
                    unpack [ get_rect_item $item_id main ] x y w h foo bar
                    unpack [ get_shadow $item_id hand ] hleft foo hright foo
                    #item 889
                    set a [ expr { $hright - $hleft } ]
                    #item 890
                    set result [ list $x $y $w $h $a $inverse ]
                } else {
                    #item 860
                    set result [ get_rect_item $item_id main ]
                    set result [ lreplace $result 5 5 $inverse ]
                }
            }
        }
    }
    #item 892
    return $result
}

proc get_rect_item { item_id role } {
    #item 881
    unpack [ get_shadow $item_id $role ] left top right bottom
    #item 882
    set w [ expr { ($right - $left) / 2 } ]
    set h [ expr { ($bottom - $top) / 2 } ]
    set x [ expr { $left + $w } ]
    set y [ expr { $top + $h } ]
    #item 883
    return [ list $x $y $w $h 0 0 ]
}

proc get_shadow { item_id role } {
    #item 1757
    variable t_item_shadows
    #item 1758
    array set shadows $t_item_shadows($item_id)
    #item 1759
    set shadow_id $shadows($role)
    #item 1760
    return [ get_shadow_by_id $shadow_id ]
}

proc get_shadow_by_id { shadow_id } {
    #item 1751
    variable t_shadows
    #item 1752
    set shadow $t_shadows($shadow_id)
    #item 1753
    return [ lrange $shadow 2 5 ]
}

proc get_shadow_item_type { shadow_id } {
    #item 1748
    variable t_shadows
    #item 1749
    set shadow $t_shadows($shadow_id)
    #item 1750
    return [ lindex $shadow 6 ]
}

proc get_shadow_type { shadow_id } {
    #item 1745
    variable t_shadows
    #item 1746
    set shadow $t_shadows($shadow_id)
    #item 1747
    return [ lindex $shadow 1 ]
}

proc get_shadows { item_id } {
    #item 1739
    variable t_item_shadows
    set shadows $t_item_shadows($item_id)
    #item 1743
    set result {}
    set length [ llength $shadows ]
    #item 17410001
    set i 1
    while { 1 } {
        #item 17410002
        if {$i < $length} {
            #item 1740
            lappend result [ lindex $shadows $i ]
            #item 17410003
            incr i 2
            continue
        } else {
            break
        }
    }
    #item 1744
    return $result
}

proc init_db { } {
    #item 771
    clear
}

proc insert { item_id type x y w h a b } {
    #item 1680
    variable t_items
    variable t_item_shadows
    #item 775
    set t_items($item_id) [ list $type $b ]
    set t_item_shadows($item_id) {}
    #item 783
    update $item_id $type $x $y $w $h $a $b
}

proc is_marked { shadow_id } {
    #item 1769
    variable t_marked
    #item 1770
    return [ info exists t_marked($shadow_id) ]
}

proc mark_shadow { shadow_id } {
    #item 1771
    variable t_marked
    #item 1772
    set t_marked($shadow_id) 1
}

proc mouse_move { delta_x delta_y } {
    #item 1540
    variable hit_shadows
    set shadows $hit_shadows
    #item 759
    if {$delta_x == 0 && $delta_y == 0} {
        
    } else {
        #item 977
        clear_affected_items
        #item 1291
        move_along_direction $shadows \
        	horizontal $delta_x
        #item 951
        set itemsx [ get_affected_items ]
        #item 1647
        clear_affected_items
        #item 1292
        move_along_direction $shadows \
        	vertical $delta_y
        #item 1646
        set itemsy [ get_affected_items ]
        #item 1648
        set all [ concat $itemsx $itemsy ]
        set items [ lsort -unique $all ]
        #item 7630001
        set _col763 $items
        set _len763 [ llength $_col763 ]
        set _ind763 0
        while { 1 } {
            #item 7630002
            if {$_ind763 < $_len763} {
                #item 7630004
                set item_id [ lindex $_col763 $_ind763 ]
                #item 766
                set resized [ get_item $item_id ]
                mv::update_item $item_id $resized
                mv::add_changed $item_id
                #item 7630003
                incr _ind763
                continue
            } else {
                break
            }
        }
    }
}

proc move_big_side { shadow_id delta direction } {
    #item 1710
    move_one_side $shadow_id $delta $direction 4 5
}

proc move_one_side { shadow_id delta direction x_index y_index } {
    #item 1730
    variable t_shadows
    #item 1731
    set shadow $t_shadows($shadow_id)
    #item 17250001
    if {$direction == "horizontal"} {
        #item 1737
        set index $x_index
    } else {
        #item 17250002
        if {$direction == "vertical"} {
            
        } else {
            #item 17250003
            error "Unexpected switch value: $direction"
        }
        #item 1735
        set index $y_index
    }
    #item 1729
    set old [ lindex $shadow $index ]
    #item 1732
    set new [ expr { $old + $delta } ]
    #item 1733
    set shadow [ lreplace $shadow $index $index $new ]
    #item 1736
    set t_shadows($shadow_id) $shadow
    #item 1734
    mark_shadow $shadow_id
}

proc move_shadow { shadow_id delta direction } {
    #item 954
    variable t_shadows
    #item 1689
    set shadow $t_shadows($shadow_id)
    #item 9090001
    if {$direction == "horizontal"} {
        #item 1697
        set first 2
        set second 4
    } else {
        #item 9090002
        if {$direction == "vertical"} {
            
        } else {
            #item 9090003
            error "Unexpected switch value: $direction"
        }
        #item 1693
        set first 3
        set second 5
    }
    #item 913
    set left [ lindex $shadow $first ]
    set right [ lindex $shadow $second ]
    #item 1690
    set left2 [ expr { $left + $delta } ]
    set right2 [ expr { $right + $delta } ]
    #item 1691
    set shadow [ lreplace $shadow $first $first $left2 ]
    set shadow [ lreplace $shadow $second $second $right2 ]
    #item 1696
    set t_shadows($shadow_id) $shadow
    #item 1692
    mark_shadow $shadow_id
}

proc move_small_side { shadow_id delta direction } {
    #item 1738
    move_one_side $shadow_id $delta $direction 2 3
}

proc opposite_orientation { orientation } {
    #item 6790001
    if {$orientation == "vertical"} {
        #item 685
        return "horizontal"
    } else {
        #item 6790002
        if {$orientation == "horizontal"} {
            
        } else {
            #item 6790003
            error "Unexpected switch value: $orientation"
        }
        #item 686
        return "vertical"
    }
}

proc shadow { item_type item_id role left top right bottom type } {
    #item 1681
    variable t_shadows
    variable t_item_shadows
    #item 1683
    variable next_shadow_id
    #item 1684
    array set shadows $t_item_shadows($item_id)
    #item 1686
    if {[ info exists shadows($role) ]} {
        #item 1687
        set shadow_id $shadows($role)
    } else {
        #item 826
        incr next_shadow_id
        set shadow_id $next_shadow_id
        set shadows($role) $shadow_id
    }
    #item 1688
    set shadow_record [ list $role $type \
    	$left $top $right $bottom \
    	$item_type $item_id ]
    set t_shadows($shadow_id) $shadow_record
    #item 1685
    set t_item_shadows($item_id) [ array get shadows ]
}

proc shadows_for_direction { shadows direction delta } {
    #item 1204
    set result {}
    #item 1206
    if {$delta == 0} {
        
    } else {
        #item 12070001
        set _col1207 $shadows
        set _len1207 [ llength $_col1207 ]
        set _ind1207 0
        while { 1 } {
            #item 12070002
            if {$_ind1207 < $_len1207} {
                #item 12070004
                set shadow_id [ lindex $_col1207 $_ind1207 ]
                #item 1209
                set type [ get_shadow_type $shadow_id ]
                #item 1208
                if {($type == "icon") || (!($type == $direction))} {
                    #item 1214
                    lappend result $shadow_id
                } else {
                    
                }
                #item 12070003
                incr _ind1207
                continue
            } else {
                break
            }
        }
    }
    #item 1205
    return $result
}

proc should_also_pull { pusher_id pusher_type other_id direction delta } {
    #item 1570
    if {(($direction == "vertical") && ($pusher_type == "horizontal")) && (!([ is_marked $other_id ]))} {
        #item 1586
        unpack [ get_shadow_by_id $pusher_id ] \
        	myleft mytop myright mybottom
        #item 1587
        unpack [ get_shadow_by_id $other_id ] \
        	oleft otop oright obottom
        #item 1611
        set other_type [ get_shadow_item_type $other_id ]
        #item 1575
        if {$delta > 0} {
            #item 1589
            incr mytop -20
            #item 1585
            if {$other_type == "address"} {
                #item 1603
                set result [ rectangles_intersect \
                	$myleft $mytop $myright $mybottom \
                	$oleft $otop $oright $obottom ]
            } else {
                #item 1598
                set result 0
            }
        } else {
            #item 1590
            incr mybottom 20
            #item 15770001
            if {($other_type == "branch") || ($other_type == "case")} {
                #item 1603
                set result [ rectangles_intersect \
                	$myleft $mytop $myright $mybottom \
                	$oleft $otop $oright $obottom ]
            } else {
                #item 1598
                set result 0
            }
        }
    } else {
        #item 1598
        set result 0
    }
    #item 1599
    return $result
}

proc update { item_id type x y w h a b } {
    #item 799
    set left [ expr { $x - $w } ]
    set right [ expr { $x + $w } ]
    set top [ expr { $y - $h } ]
    set bottom [ expr { $y + $h } ]
    #item 7840001
    if {$type == "horizontal"} {
        #item 798
        shadow $type $item_id main \
        $x $y $right $y \
        horizontal
    } else {
        #item 7840002
        if {$type == "vertical"} {
            #item 800
            shadow $type $item_id main \
            $x $y $x $bottom \
            vertical
        } else {
            #item 7840003
            if {$type == "arrow"} {
                #item 802
                if {$b} {
                    #item 805
                    set left $x
                    set right [ expr { $x + $w } ]
                    set left2 $x
                    set right2 [ expr { $x + $a } ]
                    set bottom [ expr { $y + $h } ]
                    set top $y
                } else {
                    #item 804
                    set left [ expr { $x - $w } ]
                    set right $x
                    set left2 [ expr { $x - $a } ]
                    set right2 $x
                    set bottom [ expr { $y + $h } ]
                    set top $y
                }
                #item 807
                shadow $type $item_id top $left $y $right $y \
                	horizontal
                shadow $type $item_id main $x $y $x $bottom \
                	vertical
                shadow $type $item_id bottom $left2 $bottom $right2 $bottom \
                	horizontal
            } else {
                #item 7840004
                if {$type == "if"} {
                    #item 809
                    set right2 [ expr { $right + $a } ]
                    shadow $type $item_id hand \
                    $right $y $right2 $y \
                    horizontal
                } else {
                    #item 7840005
                    if {$type == "commentout"} {
                        #item 810
                        if {$b} {
                            #item 815
                            set left2 $right
                            set right2 [ expr { $right + $a } ]
                        } else {
                            #item 814
                            set left2 [ expr { $left - $a } ]
                            set right2 $left
                        }
                        #item 816
                        shadow $type $item_id hand \
                        $left2 $y $right2 $y \
                        horizontal
                    } else {
                        
                    }
                }
                #item 808
                shadow $type $item_id main \
                $left $top $right $bottom \
                icon
            }
        }
    }
}

}
