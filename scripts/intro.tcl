package require Tk

namespace eval ui {

variable intro_happyend 0
variable intro_files {}

proc intro.init { window data } {
  global script_path
  variable intro_happyend
  variable intro_files
  
  set intro_happyend 0
  
  wm title $window "DRAKON Editor [ version_string ]"

  set intro_files [ app_settings::get_recent_files drakon_editor ]

  # Widgets
  ttk::frame $window.root -padding "5 5 5 5"

  image create photo intro_image -format GIF -file $script_path/images/drakon_editor.gif
  
  ttk::frame $window.root.greeting
  ttk::label $window.root.greeting.text -text "DRAKON Editor does not have a \"Save\" button. All your changes get saved right after you have done them.\nThat is why DRAKON Editor always needs an file to work with."
  ttk::label $window.root.greeting.logo -image intro_image

  pack $window.root.greeting.logo -side left
  pack $window.root.greeting.text -side left -fill x -expand 1
  
  label $window.root.smart -text "Holding SHIFT while dragging items on the canvas\nactivates SMART editing mode." -bg black -fg yellow
  

  ttk::button $window.root.open -text "Open existing..." -command ui::intro.open
  ttk::label $window.root.open_label -text "Choose and open a diagram file that already exists on the disk."

  ttk::button $window.root.create -text "Create new..." -command ui::intro.create
  ttk::label $window.root.create_label -text "Create a new diagram file."

  ttk::button $window.root.recent -text "Open recent" -command ui::intro.recent
  ttk::button $window.root.clear -text "Clear history" -command ui::intro.clear
  
  mw::create_listbox $window.root.files ui::intro_files
  mw::make_alternate_lines $window.root.files.list

  ttk::button $window.root.exit -text "Exit" -command exit
  

  # Layout


  grid $window.root -column 0 -row 0 -sticky nsew
  grid $window.root.greeting -row 0 -column 0 -columnspan 2 -sticky we
  grid $window.root.smart -row 1 -column 0 -columnspan 2 -sticky we

  grid $window.root.open -row 2 -column 0 -sticky new  -pady 5 -padx 5
  grid $window.root.open_label -row 2 -column 1 -sticky w
  grid $window.root.create -row 3 -column 0 -sticky new  -pady 5 -padx 5
  grid $window.root.create_label -row 3 -column 1 -sticky w
  grid $window.root.recent -row 4 -column 0 -sticky new -pady 5 -padx 5
  grid $window.root.clear -row 4 -column 1 -sticky ne -pady 5 -padx 5
  grid $window.root.files -row 5 -column 0 -sticky ew -columnspan 2
  grid $window.root.exit -row 6 -column 1 -sticky se -pady 5 -padx 5

  grid columnconfigure $window 0 -weight 1
  grid rowconfigure $window 0 -weight 1

  grid columnconfigure $window.root 1 -weight 1
  grid rowconfigure $window.root 4 -weight 1
  
  bind $window <Escape> exit
  bind $window <Return> ui::intro.open
  bind $window <Destroy> ui::intro.destroy
  bind $window.root.files.list <Double-1>  ui::intro.recent
}

proc show_intro { } {
  modal_window .intro intro.init {}
}

proc intro.recent { } {
  set selected [ intro.get_selected ]
  if { $selected == "" } { return }
  try_open $selected
}

proc good_close { } {
  variable intro_happyend

  set intro_happyend 1
  destroy .intro
}

proc try_open { filename } {
  
  if { ![ ds::openfile $filename ] } { 
    tk_messageBox -message "Error opening file: $filename" -parent .intro
    return
  }
  
  good_close
}

proc intro.open { } {
  set filename [ ds::requestopath .intro ]
  if { $filename == "" } { exit }
  try_open $filename
}

proc intro.clear { } {
  variable intro_files
  app_settings::clear_recent drakon_editor
  set intro_files {}
}

proc intro.get_selected { } {
	variable intro_files
	set files_list .intro.root.files.list
	
	set selection [ $files_list curselection ]
	if { [ llength $selection ] == 0 } {
		return ""
	}
	set first_selected [ lindex $selection 0 ]
	return [ lindex $intro_files $first_selected ]
}

proc intro.create { } {
  set filename [ ds::requestspath .drn .intro ]
  if { $filename == "" } { exit }
  if { ![ ds::createfile $filename ] } { 
    tk_messageBox -message "Error creating file: $filename" -parent .intro
    return
  }
  
  good_close
}

proc intro.destroy { } {
  variable intro_happyend
  if { !$intro_happyend } {
    set intro_happyend 1
    destroy .
  }
}

}
