namespace eval mwc {

proc create_dia_node { node_id ignored } {
	unpack [ get_node_info $node_id ] parent type foo diagram_id
	set name [ get_node_text $node_id ]
	mtree::add_item $parent $type $name $node_id
}

proc delete_dia_node { node_id ignored } {
	mtree::remove_item $node_id
}

proc rename_dia_node { node_id ignored } {
	unpack [ get_node_info $node_id ] parent type foo diagram_id
	set name [ get_node_text $node_id ]
	mtree::rename_item $node_id $name
	
	set selection [ mtree::get_selection ]
	if { [ llength $selection ] == 1 } {
		set selected_node [ lindex $selection 0 ]
		if { $selected_node == $node_id && $type == "item" } {
			set mw::current_name $name
		}
	}
}

proc get_node_text { node_id } {
	variable db
	unpack [ get_node_info $node_id ] parent type name diagram_id
	if { $type == "item" } {
		return [ $db onecolumn {
			select name from diagrams where diagram_id = :diagram_id } ]
	}
	
	return $name
}


}
