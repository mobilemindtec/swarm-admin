#!/bin/tclsh


package require tcltest

namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./handlers/stack_handler.tcl"
source "./support/util.tcl"

namespace eval app {
	variable configs
	set configs [load_configs]
} 


proc db_reset {} {
	db::execute "delete from stacks"
}

proc assert_equals {val1 val2 msg} {
	if {$val1 != $val2} {
		error "$msg: expected $val1 but have $val2"
	}		
}

test stack_create {
	test stack create
} -body {
	
	db_reset
	
	set body {}
	set request {}
	dict set body name {stack_name.yml}
	dict set body content {stack content}
	dict set body enabled true
	dict set request body $body

	stack_save $request
	set response [stack_index {}]

	set data [util::try_get $response json data]
	set status [util::try_get $response statusCode]

	return "$status [expr {[llength $data] == 1}]"

} -result {200 1}


test stack_list {
	test stack list
} -body {
	
	db_reset
	
	set body {}
	set request {}
	dict set body name {stack_name.yml}
	dict set body content {stack content}
	dict set body enabled true
	dict set request body $body

	set response [stack_save $request]
	set id [util::try_get $response json data id]
	set status [util::try_get $response statusCode]

	return "$status [expr {$id > 0}]"

} -result {200 1}

test stack_update {
	test stack update
} -body {
	
	db_reset
	
	set body {}
	set request {}
	dict set body name {stack_name.yml}
	dict set body content {stack content}
	dict set body enabled true
	dict set request body $body

	set response [stack_save $request]
	set data [util::try_get $response json data]
	set id [util::try_get $response json data id]	

	dict set data name {updated.yml}
	dict set data content {updated content}
	dict set data enabled false	

	set response [stack_update [dict create body $data]]
	set status [util::try_get $response statusCode]


	assert_equals $status 200 "update status code"

	set response [stack_edit [dict create vars [dict create id $id]]]
	set status [util::try_get $response statusCode]

	assert_equals $status 200 "edit status code"	

	set ndata [util::try_get $response json data]
	set nid [util::try_get $response json data id]

	assert_equals $id $nid id
	assert_equals [dict get $data name] [dict get $ndata name] name
	assert_equals [dict get $data content] [dict get $ndata content] content
	assert_equals [dict get $data enabled] [dict get $ndata enabled] enabled

	return true

} -result true

test stack_delete {
	test stack delete
} -body {
	
	db_reset
	
	set body {}
	set request {}
	dict set body name {stack_name.yml}
	dict set body content {stack content}
	dict set body enabled true
	dict set request body $body

	set response [stack_save $request]
	set id [util::try_get $response json data id]	
	set status [util::try_get $response statusCode]

	assert_equals $status 200 "update status code"

	set response [stack_delete [dict create vars [dict create id $id]]]
	set status [util::try_get $response statusCode]

	assert_equals $status 200 "edit status code"	

	set response [stack_edit [dict create body [dict create id $id]]]
	set status [util::try_get $response statusCode]

	assert_equals $status 404 "edit status code"	
	

	return true

} -result true



cleanupTests