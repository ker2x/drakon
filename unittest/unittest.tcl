#!/usr/bin/tclsh8.5



# Sources
source ../scripts/utils.tcl
source ../scripts/model.tcl
source ../scripts/command.tcl
source ../scripts/dedit.tcl
source ../scripts/dedit_dia.tcl
source ../scripts/mainview.tcl
source ../scripts/smart_vertex.tcl
source ../scripts/icon.action.tcl
source ../scripts/icon.vertical.tcl
source ../scripts/icon.horizontal.tcl
source ../scripts/icon.if.tcl
source ../scripts/icon.beginend.tcl
source ../scripts/search.tcl
source ../scripts/graph.tcl
source ../scripts/auto.tcl
source ../scripts/back.tcl
source ../scripts/generators.tcl
source ../scripts/alt_edit.tcl
source ../generators/c.tcl
source ../generators/tcl.tcl
source ../generators/node_sorter.tcl
source ../generators/cpp.tcl
source ../generators/nogoto.tcl
source ../generators/java.tcl

# Test utilities and mocks
source utest_utils.tcl
source mwindow_dummy.tcl

# Tests
source utils_test.tcl
source model_test.tcl
source dedit_test.tcl
source mainview_test.tcl
source search_test.tcl
source line_merge_test.tcl
source connect_graph_test.tcl
source extract_auto_test.tcl
source gen_test.tcl
source alt_test.tcl
source nogoto_test.tcl
source nogoto_src.tcl

set script_path "../"
set use_log 0

load_sqlite

if { [ llength $argv ] == 1 } {
  set test [ lindex $argv 0 ]
  testone $test
} else {
  testmain
}
