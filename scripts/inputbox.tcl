
namespace eval ui {

variable ib_userinput ""
variable ib_window ""
variable ib_callback ""
variable ib_olduserdata ""

proc foreground_win { w } {
   wm withdraw $w
   wm deiconify $w
}

proc center_window { window } {


	catch { tkwait visibility $window }
	set crect [ get_window_rect $window ]
	unpack $crect cleft ctop cwidth cheight
	
	set rect [ get_window_rect . ]
	unpack $rect left top
	
	set my_left [ expr { $left + 200 } ]
	set my_top [ expr { $top + 100 } ]
	
	set geom [ make_geometry $my_left $my_top $cwidth $cheight ]
	wm geometry $window $geom
}

proc center_window_resize { window width height } {

	catch { tkwait visibility $window }
	set crect [ get_window_rect $window ]
	unpack $crect cleft ctop cwidth cheight
	
	set rect [ get_window_rect . ]
	unpack $rect left top
	
	set my_left [ expr { $left + 200 } ]
	set my_top [ expr { $top + 100 } ]
		
	set geom [ make_geometry $my_left $my_top $width $height ]
	wm geometry $window $geom
}



proc modal_window { window init data { parent "" } } {
	catch { destroy $window }
	toplevel $window
		
	bind $ <ButtonPress> { raise $window }
	
	$init $window $data
	
	catch { tkwait visibility $window }
	catch { grab $window }
		
	foreground_win $window
}

proc make_geometry { left top width height } {
	return [ join [ list $width x $height + $left + $top ] "" ]
}

proc get_window_rect { window } {
	set left 0
	set top 0
	set geom [wm geometry $window]
	scan $geom "%dx%d+%d+%d" width height left top
	return [ list $left $top $width $height ]
}

proc init_inputbox { window data } {

	variable ib_userinput
	variable ib_window
	variable ib_callback
	variable ib_olduserdata
	
	set ib_window $window
	set title [ lindex $data 0 ]
	set ib_userinput [ lindex $data 1 ]
	set ib_callback [ lindex $data 2 ]
	set ib_olduserdata [ lindex $data 3 ]
	
	wm title $window $title
	
	ttk::frame $window.root
	
	grid $window.root -column 0 -row 0 -sticky nwse
	grid columnconfigure $window 0 -weight 1
	grid rowconfigure $window 0 -weight 1	
	
	ttk::entry $window.root.entry -textvariable ui::ib_userinput
	ttk::button $window.root.ok -text "Ok" -command ui::ib_ok
	
	ttk::button $window.root.cancel -text "Cancel" -command ui::ib_close
	
	grid columnconfigure $window.root 2 -weight 1 -minsize 50
	
	grid $window.root.entry -row 1 -column 1 -sticky we -columnspan 3 -padx 5 -pady 5
	grid $window.root.ok -row 2 -column 1 -padx 10 -pady 10
	grid $window.root.cancel -row 2 -column 3 -padx 10 -pady 10
	
	bind $window <Return> ui::ib_ok
	bind $window <Escape> ui::ib_close
	
	focus $window.root.entry
}

proc input_box { title old callback data } {
	modal_window .input init_inputbox [ list $title $old $callback $data ] .
	center_window .input
}

proc ib_close { } {
	variable ib_window
	destroy $ib_window
}

proc ib_ok { } {
	variable ib_userinput
	variable ib_callback
	variable ib_olduserdata
	set new_value [ string trim $ib_userinput ]
	if { $new_value == "" } return
	set error [ $ib_callback $ib_olduserdata $new_value ]
	if { $error != "" } {
	    tk_messageBox -message $error -parent .input
	    return
	}
	ib_close
}

proc wait_for_main { } {
	catch { tkwait visibility . }
}

proc complain { message { parent .input } } {
	tk_messageBox -type ok -message $message -parent $parent
}

proc is_mac { } {
	global tcl_platform
	if { $tcl_platform(os) == "Darwin" } {
		return 1
	}
	return 0
}

proc is_windows { } {
	global tcl_platform
	if { $tcl_platform(platform) == "windows" } {
		return 1
	}
	return 0
}

}
