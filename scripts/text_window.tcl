
namespace eval ui {

variable tw_window ""
variable tw_callback ""
variable tw_olduserdata ""
variable tw_text <bad-tw_text>
variable tw_state {}

proc tw_remember { } {
}

proc tw_restore { } {
}

proc create_tabs { n } {
  set result {}
  repeat i $n {
    set tab [ expr { $i * 4 + 1 } ]
    lappend result $tab
  }
  return $result
}

proc create_textbox { name  } {
	# Background frame
	frame $name -borderwidth 1 -relief sunken
	
	set text_path [ join [ list $name text ] "." ]
	set vscroll_path [ join [ list $name vscroll ] "." ]

	
	# Scrollbar.
	ttk::scrollbar $vscroll_path -command "$text_path yview" -orient vertical
	
	# Listbox.
	text $text_path -yscrollcommand "$vscroll_path set" -undo 1 -bd 0 -highlightthickness 0 -font main_font -wrap word 

	# Put the text and its scrollbar together.
	#pack $vscroll_path $text_path -expand yes -fill both -side right
	

	grid columnconfigure $name 1 -weight 1
	grid rowconfigure $name 1 -weight 1	
	grid $text_path -row 1 -column 1 -sticky nswe
	grid $vscroll_path -row 1 -column 2 -sticky ns

	return $text_path
}

proc noop { } { }

proc tw_init { window data } {

	variable tw_window
	variable tw_callback
	variable tw_olduserdata
	variable tw_text
	
	set tw_window $window
	set title [ lindex $data 0 ]
	set userinput [ lindex $data 1 ]
	set tw_callback [ lindex $data 2 ]
	set tw_olduserdata [ lindex $data 3 ]
	
	wm title $window $title
	
	ttk::frame $window.root
	
	grid $window.root -column 0 -row 0 -sticky nwse
	grid columnconfigure $window 0 -weight 1
	grid rowconfigure $window 0 -weight 1	
	
	set tw_text [ create_textbox $window.root.entry ]
	$tw_text insert 1.0 $userinput
	ttk::button $window.root.ok -text "Ok" -command ui::tw_ok
	if { [ ui::is_mac ] } {
		set hint "Command-Enter to save and close"
	} else {
		set hint "Control-Enter to save and close"
	}
	ttk::label $window.root.hint -text $hint
	ttk::button $window.root.cancel -text "Cancel" -command ui::tw_close
	
	grid columnconfigure $window.root 2 -weight 1 -minsize 50
	grid rowconfigure $window.root 1 -weight 1 -minsize 50
	
	grid $window.root.entry -row 1 -column 1 -sticky nwse -columnspan 3 -padx 5 -pady 5
	grid $window.root.ok -row 2 -column 1 -padx 10 -pady 10
	grid $window.root.hint -row 2 -column 2 -sticky w
	grid $window.root.cancel -row 2 -column 3 -padx 10 -pady 10
	
	mw::bind_shortcut $window ui::shortcut_handler
	
	if { [ is_mac ] } {
		bind $tw_text <Command-Return> { ui::tw_ok; break }
		bind $tw_text <Command-KeyPress> { ui::command_key  %W %K %N %k }
	} else {
		bind $tw_text <Control-Return> { ui::tw_ok; break }
	}
		
	bind $tw_text <ButtonRelease-2> { ui::noop; break }
	bind $tw_text <ButtonRelease-3> { ui::noop; break }
	
	bind $window <Escape> ui::tw_close
	
	focus $tw_text
}

proc command_key { window k n code } {

	switch $k {
		Up {
			$window mark set insert 1.0
		}
		Down {
			$window mark set insert end
		}
		Left {
			$window mark set insert {insert linestart +1c}
		}
		Right {
			$window mark set insert {insert lineend -1c}
		}
	}
}

proc shortcut_handler { window code } {
	variable tw_text
	array set codes [ ui::key_codes ]
	set selection [ $tw_text tag ranges sel ]
	set sel_start [ lindex $selection 0 ]
	set sel_end [ lindex $selection 1 ]
	if { $code == $codes(a) } {
		if { $selection != "" } {
			$tw_text tag remove sel $sel_start $sel_end
		}
		$tw_text tag add sel 1.0 end end
		focus $tw_text
	}
}

proc text_window { title old callback data } {
	modal_window .twindow tw_init [ list $title $old $callback $data ] .
	center_window_resize .twindow 500 200
}

proc tw_close { } {
	variable tw_window
	destroy $tw_window
	set tw_window <bad-text-window>
}

proc tw_ok { } {
	variable tw_window
	variable tw_callback
	variable tw_olduserdata
	variable tw_text
	
	set new_value [ $tw_text get -- 1.0 end ]
	set new_wo_trail [ string trimright $new_value ]
	$tw_callback $tw_olduserdata $new_wo_trail
	tw_close
}

}
