
package require logger 0.3

source "./services/stats_service.tcl"

namespace eval stats_handler {
  variable log
  set log [logger::init stats_handler]
}

proc stats_handler::index {request} {
	variable log
	
	try {

		set result [stats_service::all]	
		return [response::json_data_ok $result true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
		
}

proc stats_handler::save {request} {
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

proc stats_handler::update {request} {
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

proc stats_handler::edit {request} {
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

proc stats_handler::delete {request} {
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


proc stats_handler::report {request} {
	variable log
	
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

proc stats_handler::line_chart {request} {
	variable log
	
	set pathVars [dict get $request vars]
	set id [dict get $pathVars id]	


	try {

		set result [stats_service::find $id]	

		if {$result == ""} {
			return [dict create json [dict create error true message "stats $id not found"]]		
		}

		set contents [stats_service::report $result]
		set data [list]

		#puts $contents

		foreach line [split $contents \n] {
			if {$line == ""} {
				continue
			}
			set vars [split $line ,]
			set val [dict create]
			dict set val timestamp "[lindex $vars 0]_"
			dict set val label [lindex $vars 1]
			dict set val value [expr double([lindex $vars 2])]
			dict set val total [expr double([lindex $vars 3])]
			lappend data $val
		}


		return [response::json_data_ok $data true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}		
}


proc stats_handler::pie_chart {request} {
	variable log
	
	set pathVars [dict get $request vars]
	set id [dict get $pathVars id]	


	try {

		set result [stats_service::find $id]	

		if {$result == ""} {
			return [dict create json [dict create error true message "stats $id not found"]]		
		}

		set contents [stats_service::report $result]
		#puts "contents = $contents"
		set data [list]

		foreach line [split $contents \n] {
			if {$line == ""} {
				continue
			}
			set vars [split $line ,]
			set val [dict create]
			dict set val label [lindex $vars 0]
			dict set val value [expr double([lindex $vars 1])]
			dict set val total [expr double([lindex $vars 2])]
			lappend data $val
		}


		return [response::json_data_ok $data true]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}		
}

proc stats_handler::feed {request} {
	variable log


	set query [dict get $request query]
	set table [dict get $query table]
	set columns [dict get $query columns]	
	set body [dict get $request body]

	# ${log}::debug "feed $query"
	
	try {

		stats_service::feed $table $columns $body
		return [response::json_ok success ]

	} on error err {
		${log}::error $err
		return [response::json_error $err]			
	}

}
