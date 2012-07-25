namespace eval app_settings {

  proc p.path { app } {
    global env
    set name $app.settings
    set home $env(HOME)
    set path [ file join $home $name ]
    return $path  
  }

  proc open_db { app } {
    set path [ p.path $app ]
    set existed [ file exists $path ]
    if { [ catch { sqlite3 settings $path } ] } {
      return 0
    }
    
    if { !$existed } {
      settings eval {
        create table info
        (
          key text primary key,
          value text
        );
        
        create table recent_files
        (
          id integer primary key,
          path text
        );
      }
    }
    
    return 1
  }
  
  proc get_recent_files { app } {
    if { ![ open_db $app ] } {
      return {}
    }
    
    set files [ settings eval { select path from recent_files order by id desc } ]
    settings close
    return $files
  }
  
  proc add_recent_file { app file } {
	global g_filename
    if { ![ open_db $app ] } {
      return
    }
    
    set file [ file normalize $file ]
    settings eval {
	delete from recent_files where path = :file;
        insert into recent_files (path) values (:file);
    }
    settings close
	set g_filename $file
  }
  
  proc clear_recent { app } {
    if { ![ open_db $app ] } {
      return
    }
    
    settings eval { delete from recent_files }
    
    settings close
  }
}
