
package require logger 0.3

source "./services/stats_service.tcl"

variable log
set log [logger::init stats_handler]

proc stats_index {request} {
	variable log
	
	try {

		set result [stats_service::all]	
		return [response::json_data_ok $result true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
		
}

proc stats_save {request} {
	variable log
	
	set body [dict get $request body]

	try {

		set result [stats_service::save $body]
		return [response::json_data_ok $result]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stats_update {request} {
	variable log
	
	set body [dict get $request body]

	try {

		stats_service::update $body
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stats_edit {request} {
	variable log
	
	set id [dict get $request vars id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set data [stats_service::find $id]

		if {$data == ""} {
			return [response::json_not_found]
		}

		return [response::json_data_ok $data]					
				
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc stats_delete {request} {
	variable log
	
	set id [dict get $request body id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set exists [stats_service::exists $id]

		if {!$exists} {
			return [response::json_not_found]
		}

		stats_service::delete $id
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}


proc stats_report {request} {
	variable log

	puts ">>stats_report"
	
	set pathVars [dict get $request vars]
	set id [dict get $pathVars id]	

	
	try {

		set result [stats_service::find $id]	

		if {$result == ""} {
			return [dict create json [dict create error true message "stats $id not found"]]		
		}

		set content [stats_service::report $result]
		set json_data [json::json2dict $content]
		return [response::json_data_ok $json_data true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}		
}


