# Main window.



namespace eval mw {

variable canvas_width
variable canvas_height

### Public ###

proc select_listbox_item { w ordinal } {
	$w see $ordinal
	$w selection clear 0 end
	$w selection set $ordinal
	$w activate $ordinal
}

proc select_dia { diagram_id replay } {
	select_dia_kernel $diagram_id 1
	back::record $diagram_id
}

proc select_dia_kernel { diagram_id hard } {
	variable current_name
	

	set node_id [ mwc::get_diagram_node $diagram_id ]
	mtree::select $node_id
	
	mwc::fetch_view
	mv::fill $diagram_id
	update_description foo foo
	set current_name [ mwc::get_dia_name $diagram_id ]
}

proc unselect_dia { ignored replay } {
	unselect_dia_ex 0 foo
}

proc unselect_dia_ex { tree_also replay } {
	variable current_name
	set current_name ""
	if { $tree_also } {
		mtree::deselect
	}	
	mv::clear
	update_description foo foo
}

proc update_description { ig1 ig2 } {
	variable dia_edit_butt
	set descr [ mwc::get_dia_description ]
	change_description $descr 1
	if { [ mwc::get_current_dia ] == "" } {
		$dia_edit_butt configure -state disabled
	} else {
		$dia_edit_butt configure -state normal
	}
}

proc enable_undo { name } {
	.mainmenu.edit entryconfigure 0 -state normal -label "Undo: $name"
}

proc disable_undo { } {
	.mainmenu.edit entryconfigure 0 -state disabled -label "Undo"
}

proc enable_redo { name } {
	.mainmenu.edit entryconfigure 1 -state normal -label "Redo: $name"
}

proc disable_redo {	 } {
	.mainmenu.edit entryconfigure 1 -state disabled -label "Redo"
}

proc measure_text { text } {

	set font [ mwf::get_dia_font 100 ]
	set size [ font metrics $font -linespace ]

	set lines [ split $text "\n" ]
	set max_width 0
	foreach line $lines {
		set line [ string map { "\t" "dddddddd" } $line ]
		set width [ font measure $font $line ]
		if { $width > $max_width } {
			set max_width $width
		}
	}
	set line_count [ llength $lines ]
	if { $line_count == 0 } { set line_count 1 }
	set height [ expr { int($size * 1.0) * ($line_count + 0) } ]
	return [ list $max_width $height ]
}



proc get_default_family { } {
	global main_font_family
	if { $main_font_family == "" } {
		if { [ ui::is_mac ] } {
			#return system
			return Menlo
		} elseif { [ ui::is_windows ] } {
			#return Verdana
			#return "Courier New"
			return "Lucida Console"
		} else {
			#return FreeSans
			#return FreeMono
			return "Liberation Mono"
		}
	}
	return $main_font_family
}


proc get_default_font_size { } {
	global main_font_size
	
	if { $main_font_size == "" } {
		set size 10
		if { [ ui::is_mac ] } { 
			incr size 4
		}
	} else {
		set size $main_font_size
	}
	return $size
}

proc create_main_font { } {
	set family [ get_default_family ]
	set size [ get_default_font_size ]
#	puts "Createing main_font: -family $main_font_family -size $main_font_size"
	font create main_font -family $family -size $size
}


proc icon_separator { name } {
	set path .root.top.$name	
	ttk::frame $path -width 10
	pack $path -anchor nw -side left
}

proc load_gif { filename } {
	global script_path
	set path $script_path/images/$filename
	return [ image create photo -format GIF -file $path ]
}

proc icon_button { name tooltip } {
	global script_path
	set image .img.$name
	set file $script_path/images/$name.gif
	image create photo $image -format GIF -file $file

	set path .root.top.$name	
	set command [ list mwc::do_create_item $name ]
	button $path -image $image	-command $command -bd 0 -relief flat -highlightthickness 0
	
	pack $path -anchor nw -side left -padx 1 -pady 3
	bind_popup $path $tooltip
}

proc command_button { name image_file command tooltip } {
	global script_path
	set file $script_path/images/$image_file
	set image [ image create photo -format GIF -file $file ]

	set path .root.top.$name	
	button $path -image $image	-command $command -bd 0 -relief flat -highlightthickness 0
	
	pack $path -anchor nw -side left -padx 1 -pady 3
	bind_popup $path $tooltip
}




proc create_listbox { name var_name } {
	# Background frame
	frame $name -borderwidth 1 -relief sunken
	
	set list_path [ join [ list $name list ] "." ]
	set vscroll_path [ join [ list $name vscroll ] "." ]

	
	# Scrollbar.
	ttk::scrollbar $vscroll_path -command "$list_path yview" -orient vertical
	
	# Listbox.
	listbox $list_path -yscrollcommand "$vscroll_path set" -bd 0 -highlightthickness 0 -listvariable $var_name

	# Put the diagram list and its scrollbar together.
	grid columnconfigure $name 1 -weight 1
	grid rowconfigure $name 1 -weight 1	
	grid $list_path -row 1 -column 1 -sticky nswe
	grid $vscroll_path -row 1 -column 2 -sticky ns
	
	return $list_path
}

proc set_status { text } {
	variable status
	$status configure -text $text
}

proc acc { button } {
	if { [ ui::is_mac ] } {
		return ""
	} else {
		return "Ctrl-$button"
	}
}

proc create_ui { } {
	variable diagram_list
	variable canvas
	variable dia_desc
	variable dia_edit_butt
	variable status
	variable search_main
	variable show_search
	variable needle_entry
	variable current_text
	variable search_result

	variable errors_main
	variable errors_listbox
	
	variable error_label
	
	create_main_font

	wm title . "DRAKON Editor"
	
	
	
	
	
	# Window-wide frame
	ttk::frame .root
	pack .root -fill both -expand 1
	
	#button .root.butt -text "hello!" -command exit
	#pack .root.butt
	
	
	
	# Button bar at the top
	ttk::frame .root.top
	set show_search [ ttk::button .root.top.show_search -text "Search" -command mw::show_hide_search ]
	pack .root.top.show_search -side right -padx 5 -pady 5
	
	pack .root.top -fill x
	
	
	command_button description description.gif mwc::file_description "File description"
	
	icon_separator s1
	
	icon_button action Action
	icon_button insertion Insertion
	icon_button beginend Begin/End
	
	icon_separator s0
	
	icon_button vertical "Vertical line"
	icon_button horizontal "Horizontal line"
	
	icon_separator s2
	
	icon_button if IF
	icon_button arrow Arrow
	
	icon_separator s3
	
	icon_button loopstart "Loop start"
	icon_button loopend "Loop end"
	
	icon_separator s4
	
	icon_button select Select
	icon_button case Case
	
	icon_separator s5
	
	icon_button branch "Branch head"
	icon_button address "Branch foot (address)"
	
	icon_separator s6
	
	icon_button commentin "In-line comment"
	icon_button commentout "Standalone comment"
	
	# Vertical splitter
	ttk::panedwindow .root.pnd -orient horizontal
	pack .root.pnd -fill both -expand 1
	
	# Status bar
	set status [ ttk::label .root.status -text "" ]
	pack $status -fill x -side bottom
	
	
	
	# Frame at the left pane
	ttk::frame .root.pnd.left -padding "3 0 0 0"
	.root.pnd add .root.pnd.left
	
	ttk::frame .root.pnd.left.new
	ttk::button .root.pnd.left.new.dia -text "Create diagram..." -command mwc::new_dia
	
	set back [ button .root.pnd.left.new.back -image [ load_gif back.gif ] \
		-command back::come_back -bd 3 -relief flat -highlightthickness 0 ]
	bind_popup $back "Back"
	
	set forward [ button .root.pnd.left.new.forward -image [ load_gif forward.gif ] \
		-command back::go_forward -bd 3 -relief flat -highlightthickness 0 ]
	bind_popup $forward "Forward"
	
	pack .root.pnd.left.new -anchor n -side top -pady 3 -fill x
	pack .root.pnd.left.new.dia -side left
	pack .root.pnd.left.new.forward -side right
	pack .root.pnd.left.new.back -side right
	
	
	ttk::label .root.pnd.left.current -textvariable mw::current_name
	pack .root.pnd.left.current -anchor n -side top -fill x
	
	# Diagram list.
	set main_tree [ mtree::create .root.pnd.left.dialist mwc::current_dia_changed ]
	pack .root.pnd.left.dialist -fill both -expand 1
	
	# Current object description edit.
	set description_frame [ ttk::frame .root.pnd.left.description_frame ]
	set dia_desc_label [ ttk::label $description_frame.dia_desc_label -text "Description:" ]
	set dia_edit_butt [ ttk::button $description_frame.dia_edit_butt -text "Edit..." -command mwc::dia_properties ]
	pack $description_frame -fill x
	pack $dia_desc_label -pady 3 -side left
	pack $dia_edit_butt -pady 3 -side right
	
	
	set dia_desc [ text .root.pnd.left.description -width 40 -height 10 \
		-highlightthickness 0 -borderwidth 1 -relief sunken -state disabled -font main_font -wrap word ]
	pack $dia_desc -fill both
	
	# Right pane: horizontal splitter
	ttk::panedwindow .root.pnd.right -orient vertical
	.root.pnd add .root.pnd.right

	# Right pane: list of errors
	set errors_main [ ttk::frame .root.pnd.right.errors -relief sunken -padding "1 1 1 1" ]
	set errors_info [ ttk::frame $errors_main.info -padding "3 3 3 3" ]
	set errors_listbox [ create_listbox $errors_main.list mw::error_list ]
	$errors_listbox configure -height 8
	bind $errors_listbox <<ListboxSelect>> { mw::error_selected %W }
	
	pack $errors_info -side top -fill x
	pack $errors_main.list -side top -fill both -expand 1
	
	ttk::button $errors_info.verify -text "Verify" -command mw::verify
	ttk::button $errors_info.verify_all -text "Verify All" -command mw::verify_all
	ttk::button $errors_info.hide -text "Hide" -command mw::hide_errors
	set error_label [ label $errors_info.message -textvariable mw::error_message ]
	pack $errors_info.verify -side left
	pack $errors_info.verify_all -side left
	pack $errors_info.message -side left -fill x -expand 1
	pack $errors_info.hide -side right
	
	
	
	# Right pane: search panel
	set search_main [ ttk::frame .root.pnd.right.search -relief sunken -padding "1 1 1 1" ]
	
	ttk::frame $search_main.criteria -padding "3 3 3 3"
	grid rowconfigure $search_main 0 -weight 1
	grid columnconfigure $search_main 1 -weight 1
	grid $search_main.criteria -row 0 -column 0 -sticky nw
	
	set needle_label [ ttk::label $search_main.criteria.needle_label -text "Find:" ]
	set needle_entry [ ttk::entry $search_main.criteria.needle_entry -textvariable  mw::s_needle ]
	bind $needle_entry <Escape> mw::hide_search
	bind $needle_entry <Return> mw::find_all
	
	set replace_label [ ttk::label $search_main.criteria.replace_label -text "Replace:" ]
	set replace_entry [ ttk::entry $search_main.criteria.replace_entry -textvariable mw::s_replace ]
	bind $replace_entry <Escape> mw::hide_search
	
	set find_button [ ttk::button $search_main.criteria.find_button -text "Find All" -command mw::find_all ]
	set replace_all_button [ ttk::button $search_main.criteria.replace_all_button -text "Replace All" \
		-command mw::replace_all ]
	
	set case_check [ ttk::checkbutton $search_main.criteria.case_check -text "Case sensitive" -variable mw::s_case ]
	set whole_check [ ttk::checkbutton $search_main.criteria.whole_check -text "Whole word only" -variable mw::s_whole_word ]
	
	set current_radio [ ttk::radiobutton $search_main.criteria.current_radio -text "Current diagram" -variable mw::s_current_only -value current ]
	set all_radio [ ttk::radiobutton $search_main.criteria.all_radio -text "Entire file" -variable mw::s_current_only -value all ]
	
	grid $needle_label -row 0 -column 0 -sticky w
	grid $needle_entry -row 1 -column 0 -sticky we -columnspan 2
	grid $find_button -row 1 -column 2 -padx 3 -sticky we
	grid $replace_label -row 2 -column 0 -sticky w
	grid $replace_entry -row 3 -column 0 -sticky we -columnspan 2
	grid $replace_all_button -row 3 -column 2 -padx 3 -sticky we
	
	grid $case_check -row 4 -column 0 -sticky w
	grid $whole_check -row 5 -column 0 -sticky w
	grid $current_radio -row 4 -column 1 -sticky w
	grid $all_radio -row 5 -column 1 -sticky w
	
	set current_text [ text $search_main.criteria.current_text -height 1 -width 50 \
		-highlightthickness 0 -borderwidth 1 -relief sunken -state disabled -font main_font -wrap word ]
	grid $current_text -row 6 -column 0 -columnspan 3 -sticky nwse
	
	set previous_button [ ttk::button $search_main.criteria.previous_button -text "Previous" -command mw::find_previous ]
	set replace_button [ ttk::button $search_main.criteria.replace_button -text "Replace" -state disabled -command mw::replace ]
	set next_button [ ttk::button $search_main.criteria.next_button -text "Next" -command mw::find_next ]
	grid $previous_button -row 7 -column 0 -sticky w -padx 3 -pady 3
	grid $replace_button -row 7 -column 1 -padx 3 -pady 3
	grid $next_button -row 7 -column 2 -sticky e -padx 3 -pady 3
	
	
	set search_result [ create_listbox $search_main.result mw::search_result_list ]
	grid $search_main.result -row 0 -column 1 -sticky nwes
	bind $search_result <<ListboxSelect>> { mw::search_select %W }
	
	# Right pane: canvas
	set canvas [ canvas .root.pnd.right.canvas -bg "#e0e0ff" -relief sunken -bd 1 -highlightthickness 0 -cursor crosshair ]
	.root.pnd.right add $canvas -weight 100
	
	# Configure the canvas.
	$canvas configure -xscrollincrement 1 -yscrollincrement 1
	

	
	
#	wm geometry . 1000x600
	
	# Magic command before creating menus
	#option add *tearOff 0
	# Create a context menu for the diagram list.
	menu .diapop -tearoff 0
	
	# Create a context menu for the canvas.
	menu .canvaspop -tearoff 0
	
	# Main menu
	menu .mainmenu -tearoff 0
	menu .mainmenu.file -tearoff 0
	menu .mainmenu.edit -tearoff 0 
	menu .mainmenu.insert -tearoff 0
	menu .mainmenu.view -tearoff 0
	menu .mainmenu.drakon -tearoff 0	
	menu .mainmenu.generate -tearoff 0
	menu .mainmenu.help -tearoff 0
	
	
	.mainmenu add cascade -label "File" -underline 0 -menu .mainmenu.file
	.mainmenu add cascade -label "Edit" -underline 0 -menu .mainmenu.edit
	.mainmenu add cascade -label "Insert" -underline 0 -menu .mainmenu.insert
	.mainmenu add cascade -label "View" -underline 0 -menu .mainmenu.view
	.mainmenu add cascade -label "DRAKON" -underline 0 -menu .mainmenu.drakon	
	.mainmenu add cascade -label "Help" -underline 0 -menu .mainmenu.help
	
	.mainmenu.help add command -label "About..." -command ui::show_about
	
	# File submenu
	.mainmenu.file add command -label "New..." -underline 0 -command mwc::create_file
	.mainmenu.file add command -label "Open..." -underline 0 -command mwc::open_file -accelerator [ acc O ]
	.mainmenu.file add command -label "Save as..." -underline 0 -command mwc::save_as
	.mainmenu.file add command -label "Open recent..." -underline 5 -command recent::recent_files_dialog
	.mainmenu.file add separator
	.mainmenu.file add command -label "File description..." -underline 0 -command mwc::file_description
	.mainmenu.file add command -label "File properties..." -underline 5 -command fprops::show_dialog
	.mainmenu.file add separator
	.mainmenu.file add command -label "Export to PDF..." -underline 0 -command export_pdf::export
	.mainmenu.file add command -label "Export to PNG..." -underline 12 -command export_png::export
	
	# Edit submenu
	.mainmenu.edit add command -label "Undo" -underline 0 -command mwc::undo  -accelerator [ acc Z ]
	.mainmenu.edit add command -label "Redo" -underline 0 -command mwc::redo -accelerator [ acc Y ]
	.mainmenu.edit add separator
	.mainmenu.edit add command -label "Copy" -underline 0 -command { mwc::copy ignored }  -accelerator [ acc C ]
	.mainmenu.edit add command -label "Cut" -underline 1 -command { mwc::cut ignored }  -accelerator [ acc X ]
	.mainmenu.edit add command -label "Paste" -underline 0 -command { mwc::paste ignored } -accelerator [ acc V ]
	.mainmenu.edit add separator
	.mainmenu.edit add command -label "Delete" -underline 0 -command { mwc::delete ignored }  -accelerator Backspace
	.mainmenu.edit add command -label "Adjust icon sizes" -underline 0 -command { mwc::adjust_icon_sizes }

	.mainmenu.edit add separator
	.mainmenu.edit add command -label "Diagram description..." -underline 10 -command mwc::dia_properties  -accelerator [ acc D ]
	.mainmenu.edit add command -label "Select all" -underline 7 -command mwc::select_all  -accelerator [ acc A ]
	.mainmenu.edit add separator
	.mainmenu.edit add command -label "Find" -underline 0 -command mw::show_search  -accelerator [ acc F ]
	.mainmenu.edit add command -label "Go to diagram..." -underline 0 -command mwc::goto  -accelerator [ acc G ]
	.mainmenu.edit add command -label "Go to item..." -underline 6 -command mwc::goto_item  -accelerator [ acc I ]
	# Insert submenu	
	.mainmenu.insert add command -label "New diagram..." -underline 0 -command mwc::new_dia  -accelerator [ acc N ]
	.mainmenu.insert add command -label "New folder..." -underline 1 -command mwc::new_folder

	.mainmenu.insert add separator
	.mainmenu.insert add command -label "Action" -underline 0 -command { mwc::do_create_item action }
	.mainmenu.insert add command -label "Insertion" -underline 0 -command { mwc::do_create_item insertion }	
	.mainmenu.insert add command -label "Begin/End" -underline 0 -command { mwc::do_create_item beginend }
	.mainmenu.insert add separator	
	.mainmenu.insert add command -label "Vertical" -underline 0 -command { mwc::do_create_item vertical }
	.mainmenu.insert add command -label "Horizontal" -underline 0 -command { mwc::do_create_item horizontal }
	.mainmenu.insert add separator
	.mainmenu.insert add command -label "If" -underline 1 -command { mwc::do_create_item if }	
	.mainmenu.insert add command -label "Arrow" -underline 4 -command { mwc::do_create_item arrow }	
	.mainmenu.insert add separator
	.mainmenu.insert add command -label "Loop start" -underline 0 -command { mwc::do_create_item loopstart }	
	.mainmenu.insert add command -label "Loop end" -underline 5 -command { mwc::do_create_item loopend }	
	.mainmenu.insert add separator
	.mainmenu.insert add command -label "Select" -underline 0 -command { mwc::do_create_item select }
	.mainmenu.insert add command -label "Case" -underline 0 -command { mwc::do_create_item case }
	.mainmenu.insert add separator
	.mainmenu.insert add command -label "Branch" -underline 1 -command { mwc::do_create_item branch }
	.mainmenu.insert add command -label "Address" -underline 1 -command { mwc::do_create_item address }	
	.mainmenu.insert add separator	
	.mainmenu.insert add command -label "Comment in" -underline 1 -command { mwc::do_create_item commentin }
	.mainmenu.insert add command -label "Comment out" -underline 9 -command { mwc::do_create_item commentout }
	
	# View submenu
	.mainmenu.view add command -label "Zoom out" -underline 5 -command mw::zoomout -accelerator [ acc Down ]
	.mainmenu.view add command -label "Zoom 100%" -underline 5 -command mw::zoom100
	.mainmenu.view add command -label "Zoom in" -underline 5 -command mw::zoomin -accelerator [ acc Up ]

	# DRAKON submenu
	.mainmenu.drakon add command -label "Verify" -underline 0 -command mw::verify -accelerator [ acc R ]
	.mainmenu.drakon add command -label "Verify All" -underline 7 -command mw::verify_all
	.mainmenu.drakon add separator		
	.mainmenu.drakon add command -label "Generate code" -underline 0 -command gen::generate -accelerator [ acc B ]

	. configure -menu .mainmenu


	# Bind events
	
	#bind .mainmenu <<MenuSelect>> mw::update_menu
	#bind . <FocusIn> mw::main_focus_in
	#bind . <Destroy> mwc::save_view
	bind $main_tree [ right_up_event ] { mw::dia_popup %W %X %Y }
	bind $main_tree <Double-ButtonPress-1> { mwc::rename_dia }
	bind $dia_desc <Double-ButtonPress-1> { mwc::dia_properties }
	bind_popup $dia_desc "Double click to edit"

	bind $canvas <Configure> { mw::on_canvas_configure %w %h }
	bind $canvas <Motion> { mw::canvas_motion %W %x %y %s }
	bind $canvas <ButtonPress-1> { mw::canvas_ldown %W %x %y %s }
	bind $canvas <ButtonRelease-1> { mw::canvas_lup %W %x %y }
	bind $canvas [ right_down_event ] { mw::canvas_rdown %W %x %y }
	bind $canvas [ right_up_event ] { mw::canvas_popup %W %X %Y %x %y }
	if { [ ui::is_windows ] || [ ui::is_mac ] } {
		bind $canvas <MouseWheel> { mw::canvas_wheel %W %D %s }
	} else {
		bind $canvas <Button-4> { mw::canvas_wheel %W 50 %s }
		bind $canvas <Button-5> { mw::canvas_wheel %W -50 %s }
	}
	bind $canvas [ middle_down_event ] { mw::canvas_mdown %W %x %y %s }
	bind $canvas [ middle_up_event ] { mw::canvas_scrolled %W }

	bind $canvas <KeyPress> { mw::canvas_key_press %W %K %N %k }
	bind $canvas <Double-ButtonPress-1> { mw::canvas_dclick %W %x %y }
	bind $canvas <Leave> insp::reset
	
	bind_shortcut . mw::shortcut_handler
	bind_shortcut $canvas mw::canvas_shortcut_handler
	if { [ ui::is_mac ] } {
		bind . <Command-Shift-KeyPress> { mw::shift_ctrl_handler %k }
	}
  
}

proc get_filename { } {
  variable filename_tail
  return $filename_tail
}

proc title { filename } {
  variable filename_tail
	set filename_tail [ file tail $filename ]
	wm title . "$filename_tail - DRAKON Editor"	
}


proc main_font_measure { text } {
	return [ font measure main_font $text ]
}

### Private ###

# Previous mouse position
variable mouse_x0 0
variable mouse_y0 0

# The list of diagrams.
variable diagram_list { }

array set names {}


variable canvas <bad-canvas>
variable dia_desc <bad-dia_desc>
variable dia_edit_butt <bad-dia_edit_butt>
variable status <bad-status>
variable filename_tail
variable search_result <bad-list>
variable search_result_list {}
variable current_text <bad-current-text>
variable s_needle ""
variable s_replace ""
variable s_case 0
variable s_whole_word 0
variable s_current_only current
variable s_on 0
variable search_main
variable show_search
variable needle_entry

variable current_name ""

variable error_list {}
variable error_message ""
variable errors_visible 0
variable errors_main
variable errors_listbox
variable error_label

proc replace_all { } {
	variable s_needle
	variable s_case
	variable s_whole_word
	variable s_current_only
	variable search_result_list
	variable search_result
	variable s_replace
	
	if { $s_needle == "" } {
		set_status "Search string is empty."
		return
	}
	
	if { [ string trim $s_needle ] == "" && $s_whole_word } {
		set_status "Search string is empty."
		return
	}
	mwc::save_view
	
	set db $mwc::db
	set diagram_id [ mwc::editor_state $db current_dia ]
	if { $s_current_only == "current" } {
		set current_only 1
	} else {
		set current_only 0
	}
	
	set ignore_case [ expr { !$s_case } ]
	search::init $db
	set count [ search::replace_all $db $s_needle $diagram_id $current_only \
		 $s_whole_word $ignore_case $s_replace ] 	
	set search_result_list {}
	
	if { $count == 0 } {
		set message "Nothing found."
	} elseif { $count == 1 } {
		set message "1 match replaced."
	} else {
		set message "$count replacements done."
	}
	set_status "$message (Diagram names were not changed.)"
	show_result_line ""
}

proc find_references { } {
	variable s_needle
	variable s_case
	variable s_whole_word
	variable s_current_only

	set selection [ mtree::get_selection ]
	set node_id [ lindex $selection 0 ]
	set name [ mwc::get_node_text $node_id ]
	show_search

	set s_needle $name
	set s_case 1
	set s_whole_word 1
	set s_current_only all

	find_all
}

proc find_all { } {
	variable s_needle
	variable s_case
	variable s_whole_word
	variable s_current_only
	variable search_result_list
	variable search_result
	
	if { $s_needle == "" } {
		set_status "Search string is empty."
		return
	}
	
	if { [ string trim $s_needle ] == "" && $s_whole_word } {
		set_status "Search string is empty."
		return
	}
	mwc::save_view
	
	set db $mwc::db
	set diagram_id [ mwc::editor_state $db current_dia ]
	if { $s_current_only == "current" } {
		set current_only 1
	} else {
		set current_only 0
	}
	
	set ignore_case [ expr { !$s_case } ]
	search::init $db
	if { ![ search::find_all $db $s_needle $diagram_id $current_only $s_whole_word $ignore_case ] } { return }

	set search_result_list [ search::get_list ]
	set count [ search::get_match_count ]
	
	if { $count == 0 } {
		set_status "Nothing found."
	} elseif { $count == 1 } {
		set_status "1 match found."
	} else {
		set_status "$count matches found."
	}
	
	if { $count != 0 } {
		select_listbox_item $search_result 0
		show_match	
		make_alternate_lines $search_result
	} else {
		show_result_line ""
	}	
	
}

proc replace { } {
	variable s_replace
	set match [ search::get_current_match ]
	if { $match == "" } {
		set_status "Nothing to replace."
		return
	}
	set success [ search::replace $s_replace ]
	if { $success } {
		if { ![ find_next ] } {
			show_result_line ""
		}
	} else {
		set_status "Nothing replaced."
	}
}

proc find_next { } {
	variable search_result
	if { [ search::next ] } {
		set ordinal [ search::get_current_list_item ]
		select_listbox_item $search_result $ordinal
		show_match
		return 1
	}
	return 0
}

proc find_previous { } {
	variable search_result
	if { [ search::previous ] } {
		set ordinal [ search::get_current_list_item ]
		select_listbox_item $search_result $ordinal
		show_match
	}
}

proc show_match { } {
	set match [ search::get_current_match ]
	if { $match != "" } {
		set match_object [ search::get_match_object ]
		unpack $match_object type id
		if { $type == "icon" } {
			mwc::switch_to_item $id
		} elseif { $type == "diagram_name" || $type == "diagram_description" } {
			mwc::switch_to_dia $id
		}
	}
	update
	show_result_line $match
}

proc show_result_line { match } {
	variable current_text
	variable search_main
	
	$current_text configure -state normal
	$current_text  delete 1.0 end	
	
	if { $match != "" } {
		set text [ lindex $match 0 ]

		$current_text  insert 1.0 $text
		
		set active [ lindex $match 1 ]
		if { [ llength $active ] != 0 } {
			unpack $active start length
			set end [ expr { $start + $length } ]
			set middle [ expr { $start + $length / 2 } ]
			
			$current_text tag add active 1.$start 1.$end
			$current_text tag configure active -background "#ffaa00"
			$current_text see 1.$middle
		}
		
		set back [ lindex $match 2 ]
		foreach item $back {
			unpack $item start length
			set end [ expr { $start + $length } ]
			
			$current_text tag add back 1.$start 1.$end
			$current_text tag configure back -background "#cacaff"
		}
		
		$search_main.criteria.replace_button configure -state normal		
	} else {
		$search_main.criteria.replace_button configure -state disabled
	}

	$current_text configure -state disabled
}

proc search_select { w } {
	variable current_text
	
	set current [ $w curselection ]
	if { $current == "" } { return }
	
	search::set_current_list_item $current
	show_match
}

proc hide_search { } {
	variable search_main
	variable s_on
	variable show_search

	set s_on 0
	.root.pnd.right forget $search_main
	$show_search configure -text "Search"
}

proc show_search { } {
	variable search_main
	variable s_on
	variable show_search
	variable needle_entry
	
	if { !$s_on } {
		set s_on 1
		.root.pnd.right insert 0 $search_main -weight 30
		$show_search configure -text "Hide search"
		update		
		focus $needle_entry
	}
}

proc show_hide_search { } {
	variable search_main
	variable s_on
	variable show_search
	variable needle_entry
	
	if { $s_on } {
		hide_search
	} else {
		show_search
	}
	
}


# Color the list backgrounds with color stripes.
proc make_alternate_lines { list } {
	set last [ expr [ $list index end ] - 1 ]
	for { set i $last } { $i >= 0 } { incr i -1 } {
		$list itemconfigure $i -background "#ffffff"	
	}
	for { set i $last } { $i >= 0 } { incr i -2 } {
		$list itemconfigure $i -background "#f0f0ff"
	}
}


proc bind_shortcut { window handler } {
	if { [ ui::is_mac ] } {
		set event <Command-KeyPress>
	} else {
		set event <Control-KeyPress>
	}
	bind $window $event [ list $handler $window %k ]
}


proc shift_ctrl_handler { code } {
	array set codes [ ui::key_codes ]
	if { $code == $codes(z) || $code == 393306 } {
		mwc::redo
	}
}

proc shortcut_handler { window code } {
	array set codes [ ui::key_codes ]
	if { $code == $codes(y) } {
		mwc::redo
	} elseif { $code == $codes(z) } {
		mwc::undo
	} elseif { $code == $codes(f) } {
		show_hide_search
	} elseif { $code == $codes(r) } {
		verify
	} elseif { $code == $codes(Up) } {
		zoomin
	} elseif { $code == $codes(Down) } {
		zoomout
	} elseif { $code == $codes(Left) } {
		back::come_back
	} elseif { $code == $codes(Right) } {
		back::go_forward
	} elseif { $code == $codes(n) } {
		mwc::new_dia
	} elseif { $code == $codes(o) } {
		mwc::open_file
	} elseif { $code == $codes(d) } {
		mwc::dia_properties
	} elseif { $code == $codes(g) } {
		mwc::goto
	} elseif { $code == $codes(i) } {
		mwc::goto_item
	} elseif { $code == $codes(b) } {
		gen::generate
	}
}

proc canvas_shortcut_handler { window code } {
	array set codes [ ui::key_codes ]
	if { $code == $codes(a) } {
		mwc::select_all
	} elseif { $code == $codes(x) } {
		mwc::cut foo
	} elseif { $code == $codes(c) } {
		mwc::copy foo
	} elseif { $code == $codes(v) } {
		mwc::paste foo
	}
}


###	 Keyboard and mouse state queries ###

proc normalize_wheel { raw_delta } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		set amount [ expr -$raw_delta ]
	} else {
		set amount [ expr -$raw_delta * 50 ]
	}
	return $amount
}

proc right_down_event { } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		return <ButtonPress-3>
	} else {
		return <ButtonPress-2>
	}
}

proc right_up_event { } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		return <ButtonRelease-3>
	} else {
		return <ButtonRelease-2>
	}
}


proc middle_down_event { } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		return <ButtonPress-2>
	} else {
		return <ButtonPress-3>
	}
}

proc middle_up_event { } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		return <ButtonRelease-2>
	} else {
		return <ButtonRelease-3>
	}
}


proc left_button_pressed { state } {
	return [ flag_on $state 256 ]
}

proc control_pressed { state } {
	log $state
	if { [ ui::is_windows ] } {
		return [ expr { $state == 12 } ]
	} else {
		return [ expr { $state == 4 || $state == 8 || $state == 20 } ]
	}
}



proc right_button_pressed { state } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		set button 1024
	} else {
		set button 512
	}
	return [ flag_on $state $button ]
}

proc middle_button_pressed { state } {
	global tcl_platform
	if { ![ ui::is_mac ] } {
		set button 512
	} else {
		set button 1024
	}
	return [ flag_on $state $button ]
}

proc shift_pressed { state } {
	return [ flag_on $state 1 ]
}

proc remember_mouse { x y } {
	variable mouse_x0 
	variable mouse_y0
	set mouse_x0 $x
	set mouse_y0 $y
}

proc get_dx { x } {
	variable mouse_x0
	return [ expr { $x - $mouse_x0 } ]
}

proc get_dy { y } {
	variable mouse_y0
	return [ expr { $y - $mouse_y0 } ]
}

proc change_description { new replay } {
	variable dia_desc
	
	
	$dia_desc configure -state normal
	$dia_desc  delete 1.0 end
	$dia_desc  insert 1.0 $new
	$dia_desc configure -state disabled
}

proc update_menu { } {
	set copy 3
	set cut 4
	set paste 5
	set delete 7
	set edit 9
	set all 10
	if { [ can_paste_items ] } {
		.mainmenu.edit entryconfigure $paste -state normal
	} else {
		.mainmenu.edit entryconfigure $paste -state disable
	}
	
	if { [ mwc::has_selection ] } {
		.mainmenu.edit entryconfigure $copy -state normal
		.mainmenu.edit entryconfigure $cut -state normal
		.mainmenu.edit entryconfigure $delete -state normal
	} else {
		.mainmenu.edit entryconfigure $copy -state disabled
		.mainmenu.edit entryconfigure $cut -state disabled
		.mainmenu.edit entryconfigure $delete -state disabled
	}
	
	if { [ mwc::get_current_dia ] == "" } {
		.mainmenu.edit entryconfigure $edit -state disabled
		.mainmenu.edit entryconfigure $all -state disabled
	} else {
		.mainmenu.edit entryconfigure $edit -state normal	
		.mainmenu.edit entryconfigure $all -state normal		
	}
}

proc canvas_popup { window x_world y_world x y } {
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	if { [ focus ] == "" } { 
		return
	}


	.canvaspop delete 0 1000
	set commands [ mwc::get_context_commands $cx $cy ]
	if { [ llength $commands ] == 0 } { return }
	foreach command $commands {
		set type [ lindex $command 0 ]
		if { $type == "separator" } {
			.canvaspop add separator
		} else {
			set text [ lindex $command 1 ]
			set state [ lindex $command 2 ]
			set procedure [ lindex $command 3 ]
			set proc_arg [ lindex $command 4 ]
		
			set callback [ list $procedure $proc_arg ]
			.canvaspop add command -label $text -state $state -command $callback
		}
	}
	tk_popup .canvaspop $x_world $y_world
}



proc dia_popup { window x_world y_world } {
	if { [ focus ] == "" } { return }
	.diapop delete 0 1000
	
	set selection [ mtree::get_selection ]
	set count [ llength $selection ]
	set has_selection [ expr { $count > 0 } ]
	set one [ expr { $count == 1 } ]
	
	set diagram_selected 0
	if { $one } {
		set node_id [ lindex $selection 0 ]
		unpack [ mwc::get_node_info $node_id ] parent type name diagram_id
		if { $type == "item" } {
			set diagram_selected 1
		}
	}
	
	set paste [ can_paste_nodes ]

	
	if { $one } {
		if { $diagram_selected } {
			.diapop add command -label "Find all references" -command mw::find_references
		} else {
			.diapop add command -label "Collapse" -command mtree::collapse
			.diapop add separator
			.diapop add command -label "New diagram inside this folder..." -command mwc::new_dia_here
			.diapop add command -label "New folder inside this folder..." -command mwc::new_folder_here
		}
	}

	.diapop add command -label "New diagram..." -command mwc::new_dia
	.diapop add command -label "New folder..." -command mwc::new_folder		


	if { $has_selection } {
		.diapop add separator		
		.diapop add command -label "Copy" -command mwc::copy_tree
		.diapop add command -label "Cut" -command mwc::cut_tree
	}

	if { $paste } {
		.diapop add command -label "Paste" -command mwc::paste_tree
		if { $one && !$diagram_selected } {
			.diapop add command -label "Paste inside this folder" -command mwc::paste_tree_here
		}
	}

	
	if { $diagram_selected } {
		.diapop add separator		
		.diapop add command -label "Description..." -command mwc::dia_properties
	}
	
	if { $one } {
		if { !$diagram_selected } {
			.diapop add separator	
		}
		.diapop add command -label "Rename..." -command mwc::rename_dia
	}
	
	if { $has_selection } {
		.diapop add separator
		.diapop add command -label "Delete" -command mwc::delete_tree_items
	}
	
	if { $diagram_selected } {
		.diapop add separator	
		.diapop add command -label "Export to PDF..." -command export_pdf::export
		.diapop add command -label "Export to PNG..." -command export_png::export
	}
	
	tk_popup .diapop $x_world $y_world
}

proc edit { } {
	puts edit
}

proc canvas_scrolled { window } {
	set x [ $window canvasx 0 ]
	set y [ $window canvasy 0 ]
	mwc::scroll $x $y
}

proc scroll { scr replay } {
	variable canvas
	
	if { $replay } {
		set x [ lindex $scr 0 ]
		set y [ lindex $scr 1 ]
		
		set x0 [ $canvas canvasx 0 ]
		set y0 [ $canvas canvasy 0 ]
		set dx [ expr { int($x - $x0) } ]
		set dy [ expr { int($y - $y0) } ]
		
		$canvas xview scroll $dx units
		$canvas yview scroll $dy units
	}
}

proc update_cursor { cursor } {
  variable canvas
  switch $cursor {
    "item" {
      set c fleur
    }
    "handle" {
      set c hand2
    }
    default {
      set c arrow
    }
  }
  $canvas configure -cursor $c
}

proc canvas_motion { window x y s } {		
	global g_loaded
	if { !$g_loaded } { return }
	set dx [ mw::get_dx $x ]
	set dy [ mw::get_dy $y ]
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	
	mw::remember_mouse $x $y

	set args [ list $x $y $cx $cy $dx $dy ]
	
	set shift [ shift_pressed $s ]
	if { [ mw::left_button_pressed $s ] } {
		mwc::lmove $args
	} elseif { [ mw::middle_button_pressed $s ] } {
		$window xview scroll [ expr -$dx ] units
		$window yview scroll [ expr -$dy ] units
	} elseif { ![ mw::right_button_pressed $s ] } {
		mwc::hover $cx $cy $shift
	}
}

proc canvas_rect { } {
	variable canvas_width
	variable canvas_height
	variable canvas
	set left [ $canvas canvasx 0 ]
	set top [ $canvas canvasy 0 ]
	set right [ expr { $left + $canvas_width } ]
	set bottom [ expr { $top + $canvas_height } ]
	
	return [ list $left $top $right $bottom ]
}

proc canvas_key_press { window k n code } {

	array set codes [ ui::key_codes ]
	set items {
		a action
		n insertion
		g beginend
		v vertical
		h horizontal
		i if
		r arrow
		l loopstart
		e loopend
		s select
		c case
		b branch
		d address
	}
	
	if { $k == "Delete" } {
		mwc::delete foo
	} elseif { $k == "BackSpace" } {
		mwc::delete foo
	} else {
		foreach { shortcut command } $items {
			if { $code == $codes($shortcut) } {
				mwc::do_create_item $command
				return
			}
		}
	}
}

proc unpack_items { content expected_type } {
	if { [ llength $content ] != 4 } { return {} }
	unpack $content signature version type items_data
	if { $signature != "DRAKON" } { return {} }
	if { $version != [ version_string ] } { return {} }
	if { $type != $expected_type } { return {} }
	return $items_data
}


proc can_paste { expected_type } {
	if { [catch { 
		set content [ clipboard get -type STRING ]
		set items_data [ unpack_items $content $expected_type ]	
		} catch_result ]} {
		return 0
	}
	
	return [ llength $items_data ]
}


proc clipboard_type { } {
	return UTF8_STRING
}

proc put_to_clipboard { items_data type } {
	set content_list [ list DRAKON [ version_string ] $type $items_data ]
	set content " $content_list "
	clipboard clear
	clipboard append -type STRING -format [ clipboard_type ] -- $content
}


proc take_from_clipboard { type } {
	if {[catch {
		set content [ clipboard get -type STRING ]
		set items_data [ unpack_items $content $type ]  } catch_result ] } {
		return {}
	}

	return $items_data
}

proc put_items_to_clipboard { items_data } {
	put_to_clipboard $items_data "items"
}


proc take_items_from_clipboard { } {
	return [ take_from_clipboard "items" ]
}

proc can_paste_items { } {
	return [ can_paste "items" ]
}

proc put_nodes_to_clipboard { node_data } {
	put_to_clipboard $node_data "nodes"
}


proc take_nodes_from_clipboard { } {
	return [ take_from_clipboard "nodes" ]
}

proc can_paste_nodes { } {
	return [ can_paste "nodes" ]
}


proc canvas_dclick { window x y } {
	focus $window
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	
	mwc::double_click $cx $cy
}

proc canvas_mdown { window x y s } {
	focus $window
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]

	mw::remember_mouse $x $y
}

proc canvas_ldown { window x y s } {
	global g_loaded
	if { !$g_loaded } { return }

	focus $window
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]

	mw::remember_mouse $x $y
	
	set args [ list $x $y $cx $cy ]
	set ctrl [ control_pressed $s ]
	set shift [ shift_pressed $s ]
	mwc::ldown $args $ctrl $shift
}

proc canvas_rdown { window x y } {
	global g_loaded
	if { !$g_loaded } { return }

	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	
	mwc::rdown $cx $cy
}

proc canvas_lup { window x y } {
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	
	set args [ list $x $y $cx $cy ]
	mwc::lup $args
}

proc canvas_rclick { window x y }	 {
	set cx [ $window canvasx $x ]
	set cy [ $window canvasy $y ]
	
	set args [ list $x $y $cx $cy ]
	mwc::rclick $args
}

proc on_canvas_configure { w h } {
	variable canvas_width
	variable canvas_height
	set canvas_width $w
	set canvas_height $h
}

proc main_focus_in { } {
	set current [ mwc::get_current_dia ]
	if { $current != "" } {
		select_dia $current 1
	}
}

proc zoomin { } {
	variable canvas_width
	variable canvas_height
	mwc::change_zoom_up $canvas_width $canvas_height
	insp::reset
}

proc zoomout { } {
	variable canvas_width
	variable canvas_height
	mwc::change_zoom_down $canvas_width $canvas_height
	insp::reset
}

proc zoom100 { } {
	variable canvas_width
	variable canvas_height
	mwc::change_zoom_to $canvas_width $canvas_height 100
	insp::reset
}

proc canvas_wheel { window delta s } {
	variable canvas_width
	variable canvas_height
	set amount [ normalize_wheel $delta ]
	set x0 [ $window canvasx 0 ]
	set y0 [ $window canvasy 0 ]	

	if { [ shift_pressed $s ] } {
		set x1 [ expr { $x0 + $amount } ]
		set y1 $y0
		$window xview scroll $amount units
		mwc::scroll $x1 $y1
	} elseif { [ control_pressed $s ] } {
		set cw $canvas_width
		set ch $canvas_height
		if { $amount > 0 } {
			mwc::change_zoom_down $cw $ch
		} else {
			mwc::change_zoom_up $cw $ch
		}
	} else {
		set x1 $x0
		set y1 [ expr { $y0 + $amount } ]
		$window yview scroll $amount units
		mwc::scroll $x1 $y1
	}
	
	insp::reset
} 

proc verify { } {
	show_errors
	
	mwc::save_view
	
	set db $mwc::db
	set diagram_id [ mwc::editor_state $db current_dia ]
	if { $diagram_id == "" } { return }
	
	graph::verify_one $db $diagram_id
	
	get_errors
}

proc get_errors { } {
	variable error_list
	variable error_message
	variable errors_listbox
	variable error_label

	set error_list [ graph::get_error_list ]
	make_alternate_lines $errors_listbox
	if { [ llength $error_list ] == 0 } {
		set error_message "Your drawing looks good."
		$error_label configure -bg "#d0ffd0"
		return 1
	} else {
		set error_message "Some errors found."
		$error_label configure -bg "#ffd0d0"
		return 0
	}
}

proc verify_all { } {
	show_errors
	
	mwc::save_view
	
	set db $mwc::db
	
	graph::verify_all $db
	
	return [ get_errors ]
}


proc error_selected { listbox } {
	set current [ $listbox curselection ]
	if { $current == "" } { return }
	
	set error_info [ graph::get_error_info $current ]
	if { $error_info == "" } { return }
	
	unpack $error_info diagram_id items
	
	if { [ llength $items ] == 0 } {
		mwc::switch_to_dia $diagram_id
	} else {
		set item [ lindex $items 0 ]
		mwc::switch_to_item $item
	}
}

proc show_errors { } {
	variable errors_visible
	variable errors_main
	variable error_list
	variable error_message
	variable error_label
	
	set error_list {}
	set error_message ""
	$error_label configure -bg "#ffffff"
	
	
	if { $errors_visible } { return }
	set errors_visible 1
	
	
	.root.pnd.right add $errors_main
}

proc hide_errors { } {
	variable errors_visible
	variable errors_main

	if { !$errors_visible } { return }
	set errors_visible 0
	.root.pnd.right forget $errors_main
}


}
