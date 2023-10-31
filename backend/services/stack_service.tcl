package require logger

source "./database/db.tcl"
source "./support/uuid.tcl"

namespace eval stack_service {

	variable log
	variable cache

	set cache [dict create]
	set log [logger::init stack_service] 

}


proc stack_service::validate {data} {


	
}

proc stack_service::today {{format "%Y-%m-%d %H:%M:%S"}} {
	set now [clock seconds]
	return [clock format $now -format $format] 
}

proc stack_service::prepare {data} {
	set stack [dict create]
	dict set stack name [dict get $data name]
	dict set stack content [dict get $data content]
	dict set stack enabled [dict get $data enabled]
	dict set stack updated_at [today]
	return $stack
}


proc stack_service::save {data} {
	set stack [prepare $data]
	dict set stack created_at [today] 
	
	set rs [db::insert stacks $stack]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	return [$rs get_data]
}

proc stack_service::update {data} {
	set stack [prepare $data]
	dict set stack id [dict get $data id] 
	
	set rs [db::update stacks $stack]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc stack_service::all {} {

	set rs [db::all stacks [list id name content enabled created_at updated_at]]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set stack [rs_to_entity $it]
		lappend results $stack
	}

	return $results 
}

proc stack_service::find {id} {

	set rs [db::one stacks [list id name content enabled created_at updated_at] $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]

	if {$data == ""} {
		return ""
	}	

	return [rs_to_entity $data]
}

proc stack_service::delete {id} {

	set rs [db::delete stacks $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	
}

proc stack_service::exists {id} {

	set rs [db::delete stacks $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set count [lindex $data 0]

	return [expr {$count > 0}]
}

proc stack_service::rs_to_entity {rs} {

	set enabled [lindex $rs 3]

	switch $enabled {
		0 {
			set enabled false
		}
		1 {
			set enabled true
		}
	}

	set id [lindex $rs 0]

	#puts "ID = $id, int? [string is integer -strict $id]"

	set stack [dict create]
	dict set stack id $id
	dict set stack name [lindex $rs 1]
	dict set stack content [lindex $rs 2]
	dict set stack enabled $enabled
	dict set stack createdAt [lindex $rs 4]
	dict set stack updatedAt [lindex $rs 5]	
	return $stack
}