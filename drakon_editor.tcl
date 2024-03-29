#!/usr/bin/env tclsh8.5

set main_font_size ""
set main_font_family ""
set use_log 0

set g_loaded 0
set g_filename ""

proc require { package errors } {
	if { [ catch {
	package require $package
	} message ] } {
		puts $message
		foreach error $errors {
			puts $error
		}
		exit
	}
}

set script_path [ file dirname [ file normalize [ info script ] ] ]

set scripts [ glob "$script_path/scripts/*.tcl" ]
foreach script $scripts {
  source $script
}

load_sqlite

require snit {
	"This script requires snit package."
	"Consider installing tcllib"
}

require Tk {
	"This script requires Tk package."
	"Consider installing tk8.5 or later."
}


require Img {
	"This script requires Img package."
	"Consider installing libtk-img."
}

if { $tk_version < 8.5 } {
	puts "This script requires Tk package of version at least 8.5."
	puts "Consider installing tk8.5 or later."
	exit
}



load_generators

# The dir global variable is required by pdf4tcl07
set dir $script_path/pdf4tcl07
set pdf_pkg [ file join $dir pkgIndex.tcl]
source $pdf_pkg
package require pdf4tcl


namespace eval ds {
variable db mdb

proc requestopath { { parent . } } {
	return [ tk_getOpenFile -parent $parent ]
}


proc requestspath { extension { parent . } } {

	return [ tk_getSaveFile -parent $parent -defaultextension $extension ]
}


proc shouldcreate { } {
	set reply [ tk_dialog .foo "Choose action" \
		"Do you want to open an existing file or create a new one?" \
		"" 0 Open Create Cancel ]
	switch $reply {
		0 { return open }
		1 { return create }
		default { return cancel }
	}
}


proc saveasfile { filename } {
	variable db
	set message [ mod::save_as $db $filename ]

	if { $message != "" } {
		puts $message
		return 0
	}

	reload $filename
	return 1
}


proc openfile { filename } {
	variable db
	set result [ mod::open $db $filename drakon ]
	set message [ lindex $result 1 ]

	if { $message != "" } {
		log $message
		return 0
	}

	set versions [ lindex $result 0 ]
	set start_version [ lindex $versions 1 ]
	if { $start_version != [ application_start_version ] } {
		if { $start_version == "" } { set start_version "no version" }
		log "Incompatible version. Expected [ application_start_version ], but got $start_version"
		mod::close $db
		return 0
	}

	upgrade
	reload $filename
	return 1
}

proc create_tree_node { diagram_id } {
	variable db
	set node_id [ $db onecolumn {
		select node_id
		from tree_nodes
		where diagram_id = :diagram_id } ]
	if { $node_id  == "" } {
		$db eval {
			insert into tree_nodes (parent, type, diagram_id) values (0, 'item', :diagram_id)
		}
	}
}

proc upgrade { } {
	variable db
	set current_version [ application_version ]
	set file_version [ $db onecolumn { select value from info where key = 'version' } ]
	set name [ $db onecolumn {
		SELECT name FROM sqlite_master WHERE type='table' AND name='tree_nodes' } ]
	if { $name == "" } {
		$db eval {
			create table tree_nodes
			(
				node_id integer primary key,
				parent integer,
				type text,
				name text,
				diagram_id integer
			);
			alter table items add column color text;
			alter table items add column format text;
			alter table items add column text2 text;
			create unique index node_for_diagram on tree_nodes (diagram_id);
		}
	}
	$db eval {
		select diagram_id from diagrams
	} {
		create_tree_node $diagram_id
	}
	if { $file_version < 5 } {
		$db eval { update info set value = :current_version where key = 'version' }
	}
}

proc reload { filename } {
	global g_loaded
	variable db
	mv::init $db $mw::canvas
	mwc::init $db

	mw::title $filename
	mwc::fill_tree_with_nodes

	set diagram_id [ mwc::get_current_dia ]
	if { $diagram_id != "" } {
		mw::select_dia $diagram_id 1
		back::record $diagram_id
	}

	mwc::update_undo
	app_settings::add_recent_file drakon_editor $filename
	set g_loaded 1
}

proc createfile { filename } {
	global script_path
	variable db
	set init_script [ read_all_text $script_path/scripts/schema.sql ]
	set message [ mod::create $db $filename drakon \
    [ application_version ] [ application_start_version ] \
    $init_script ]

	if { $message != "" } {
		log $message
		return 0
	}



	reload $filename
	mwc::do_create_dia "Untitled" 1 0
	return 1
}


proc complain_file { file } {
	set message "Cannot open file $file."
	ui::complain $message .
}


proc usefile { filename } {
	if { ![ openfile $filename ] } {
		complain_file $filename
		ui::show_intro
	}
}


}

### main ###

mw::create_ui
mw::init_popup
ui::wait_for_main
update
if { $argc > 0 } {
	set filename [ lindex $argv 0 ]
	ds::usefile $filename
} else {
	ui::show_intro
}
