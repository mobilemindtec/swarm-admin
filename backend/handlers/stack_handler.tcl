
package require logger 0.3

source "./services/stack_service.tcl"

namespace eval stack_handler {
  variable log
  set log [logger::init stack_handler]
}

proc stack_handler::index {request} {
	variable log
	
	try {

		set result [stack_service::all]	
		return [response::json_data_ok $result true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
		
}

proc stack_handler::save {request} {
	variable log
	
	set body [dict get $request body]

	try {

		set result [stack_service::save $body]
		return [response::json_data_ok $result]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stack_handler::update {request} {
	variable log
	
	set body [dict get $request body]

	try {

		stack_service::update $body
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stack_handler::edit {request} {
	variable log
	
	set id [dict get $request vars id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set data [stack_service::find $id]

		if {$data == ""} {
			return [response::json_not_found]
		}

		return [response::json_data_ok $data]					
				
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stack_handler::delete {request} {
	variable log
	
	set id [dict get $request body id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set exists [stack_service::exists $id]

		if {!$exists} {
			return [response::json_not_found]
		}

		stack_service::delete $id
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}





