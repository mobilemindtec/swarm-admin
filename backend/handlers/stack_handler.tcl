
package require logger 0.3

source "./services/stack_service.tcl"

variable log
set log [logger::init stack_handler]

proc stack_index {request} {
	variable log
	
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set result [stack_service::all]	

		if {$result == ""} {
			dict set response data {[]}
		} else {
			dict set response data $result
		}
		
	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode list true]
}

proc stack_save {request} {
	variable log
	
	set body [dict get $request body]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set result [stack_service::save $body]
		dict set response data $result
		
	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]
}

proc stack_update {request} {
	variable log
	
	set body [dict get $request body]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		stack_service::update $body

	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]
}

proc stack_edit {request} {
	variable log
	
	set id [dict get $request vars id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set data [stack_service::find $id]

		if {$data == ""} {
			set statusCode 404
		} else {
			dict set response data $data
		}
				
	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]
}

proc stack_delete {request} {
	variable log
	
	set id [dict get $request body id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set exists [stack_service::exists $id]

		if {!$exists} {
			set statusCode 404
		} else {			
			stack_service::delete $id
		}
				
	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]	
}





