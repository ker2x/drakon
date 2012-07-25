# Test utilities

proc tproc { name args body } {
	global ut_all_tests
	
	lappend ut_all_tests $name
	proc $name $args $body
}

proc equal { actual expected { comment "" } } {
	#puts "actual:   $actual"
	#puts "expected: $expected"
	#puts ""
	
	
	global ut_current_test
	if { $actual != $expected } {
		if { $actual == "" } { set actual <empty> }
		if { $expected == "" } { set expected <empty> }
		set message "\n    $ut_current_test: equal:\nactual  : $actual\nexpected: $expected\n$comment\n"
		error $message
	}
}

proc list_equal { actual expected } {
	global ut_current_test
	set i 0
	foreach act $actual exp $expected {
		if { $act != $exp } {
			puts $actual
			set message "\n    $ut_current_test: list_equal:\nindex   : $i\nactual  : $act\nexpected: $exp\n"
			error $message
		}
		incr i
	}
}

proc array_equal { actual expected } {
	array set actual_a $actual
	array set expected_a $expected
	set actual_keys [ lsort -dictionary [ array names actual_a ] ]
	set expected_keys [ lsort -dictionary [ array names expected_a ] ]
	list_equal $actual_keys $expected_keys
	foreach key $actual_keys {
		set actual_item $actual_a($key)
		set expected_item $expected_a($key)
		equal $actual_item $expected_item
	}
}

### main ###

proc testmain { } {
	global ut_all_tests ut_current_test
	
	foreach test $ut_all_tests {
		set ut_current_test $test
		puts $test
		$test
	}
}

proc testone { torun } {
	global ut_all_tests ut_current_test
	
	foreach test $ut_all_tests {
    if { $torun == $test } {
      set ut_current_test $test
      puts $test
      $test
    }
	}
}

