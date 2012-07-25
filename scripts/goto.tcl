
namespace eval jumpto {

array set diagrams {}


variable name ""
variable window <bad-window>
variable visible {}

proc init { win data } {

	wm title $win "Go to diagram"
	
	set root [ ttk::frame $win.root -padding "5 0 5 0" ]

	ttk::entry $root.name -textvariable jumpto::name -width 40 -validate key -validatecommand { jumpto::name_changed %P }
	set listbox [ mw::create_listbox $root.list jumpto::visible ]	
	set butt_panel [ ttk::frame $root.buttons ]
	set ok [ ttk::button $butt_panel.ok -command jumpto::ok -text Ok ]
	set cancel [ ttk::button $butt_panel.cancel -command jumpto::close -text Cancel ]

	pack $root -expand yes -fill both
	
	pack $root.name -fill x -padx 5 -pady 10
	pack $root.list -fill both -expand yes
	pack $butt_panel -fill x

	pack $cancel -padx 10 -pady 10 -side right	
	pack $ok -padx 10 -pady 10 -side right

	

	bind $win <Return> jumpto::ok
	bind $win <Escape> jumpto::close
	bind $root.name <KeyPress-Down> [ list jumpto::moved_to_list $listbox ]
	bind $listbox <<ListboxSelect>> { jumpto::selected %W }
	bind $listbox <Double-ButtonPress-1> jumpto::ok	

	focus $root.name
}

proc name_changed { new } {
	variable visible
	
	if { $new == "" } {
		set visible [ get_all ]
	} else {
		set visible [ get_matching $new ]
	}

	return 1
}

proc moved_to_list { listbox } {
	variable visible
	focus $listbox
	if { [ llength $visible ] > 0 } {
		mw::select_listbox_item $listbox 0
		selected $listbox
	}
}

proc selected { listbox } {
	variable name
	variable visible
	
	set current [ $listbox curselection ]
	if { $current == "" } { return }
	
	set name [ lindex $visible $current ]
}

proc goto_dialog { dia_names_to_ids } {
	variable diagrams
	variable window
	variable name
	variable visible
	
	array unset diagrams
	array set diagrams $dia_names_to_ids

	set window .jump_to
	set name ""
	set visible [ get_all ]
	
	ui::modal_window $window jumpto::init foo
	ui::center_window $window
}

proc get_all { } {
	variable diagrams
	return [ lsort -dictionary [ array names diagrams ] ]
}

proc get_matching { substring } {
	set needle [ string tolower $substring ]
	set all [ get_all ]
	set result {}
	
	foreach name $all {
		set current [ string tolower $name ]
		if { [ string first $needle $current ] != -1  } {
			lappend result $name
		}
	}
	
	return $result
}

proc find_equal { name } {
	variable diagrams
	foreach diagram_name [ array names diagrams ] {
		if { [ string equal -nocase $name $diagram_name ] } {
			return $diagram_name
		}
	}
	return ""
}

proc close { } {
	variable window
	destroy $window
}

proc ok { } {
	variable window
	variable name
	set diagram_name [ find_equal $name ]
	if { $diagram_name == "" } {
		tk_messageBox -message "Diagram '$name' not found." -type ok -parent $window
		return
	}
	
	set diagram_id [ mwc::get_dia_id $diagram_name ]
	mwc::switch_to_dia $diagram_id
	
	destroy $window
}


}
