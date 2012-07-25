
package require Tk

namespace eval mwd {

variable name ""
variable root <bad-root>
variable type silhouette
variable window <bad-window>
variable callback
variable sibling 0

proc create_d_init { win data } {
	variable name
	variable root
	variable window
	variable callback
	variable sibling
	variable type

	set window $win
	unpack $data callback sibling

	set type primitive
	set name ""

	wm title $window "Create diagram"
	set root [ ttk::frame $window.root  ]
	ttk::entry $root.name -textvariable mwd::name -width 40
	set middle [ ttk::frame $root.middle -padding "5 5 5 5" ]
	ttk::radiobutton $middle.sil -text "Silhouette" -value silhouette -variable mwd::type
	ttk::radiobutton $middle.pri -text "Primitive" -value primitive -variable mwd::type
	set low [ ttk::frame $root.lower -padding "5 0 5 0" ]
	ttk::button $low.ok -text Ok -command mwd::ok
	ttk::button $low.cancel -text Cancel -command mwd::close
	

	pack $root -expand yes -fill both
	pack $root.name -expand yes -fill x -padx 5 -pady 10
	pack $middle -expand yes -fill both
	pack $middle.sil -side left
	pack $middle.pri -side left
	pack $low -expand yes -fill x
	pack $low.cancel -side right -padx 5 -pady 10
	pack $low.ok -side right -padx 5 -pady 10

	bind $window <Return> mwd::ok
	bind $window <Escape> mwd::close

	focus $root.name
}

proc create_diagram_dialog { callback sibling } {
	ui::modal_window .create_d mwd::create_d_init [ list $callback $sibling ]
	ui::center_window .create_d
}


proc ok { } {
  variable window
  variable callback
	variable sibling
  variable name
  variable type
  if { $type == "primitive" } {
    set sil 0
  } else {
    set sil 1
  }

  set trimmed [ string trim $name ]
  if { $trimmed == "" } {
    tk_messageBox -message "No text entered." -parent $window
    return
  }

  set result [ $callback $name $sil $sibling ]
  if { $result != "" } {
    tk_messageBox -message $result -parent $window
    return
  }

  destroy $window
}

proc close { } {
  variable window
  destroy $window
}

}

