
package require logger 0.3

source "./services/aws_codebuild_app_service.tcl"

variable log
set log [logger::init aws_codebuild_app_handler]

proc aws_codebuild_app_index {request} {
	variable log
	
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set result [aws_codebuild_app_service::all]	

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
	
	return [dict create json $response statusCode $statusCode]
}

proc aws_codebuild_app_save {request} {
	variable log
	
	set body [dict get $request body]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set result [aws_codebuild_app_service::save $body]
		dict set response data $result
		
	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]
}

proc aws_codebuild_app_update {request} {
	variable log
	
	set body [dict get $request body]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		aws_codebuild_app_service::update $body

	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]
}

proc aws_codebuild_app_edit {request} {
	variable log
	
	set id [dict get $request vars id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {

		set data [aws_codebuild_app_service::find $id]

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

proc aws_codebuild_app_delete {request} {
	variable log
	
	set id [dict get $request body id]
	set response [dict create error false messages ""]
	set statusCode 200

	try {
		
		set exists [aws_codebuild_app_service::exists $id]

		if {!$exists} {
			set statusCode 404
		} else {		
			aws_codebuild_app_service::delete $id
		}	

	} on error err {		
		${log}::error $err
		dict set $response message $err
		dict set $response error true 		
		set statusCode 500
	}
	
	return [dict create json $response statusCode $statusCode]	
}


proc aws_codebuild_app_clone {request} {
	variable log
	

	set id [dict get $request vars id]
	set response [dict create error false messages ""]
	set statusCode 200

	${log}::debug "aws_codebuild_app_clone $id"

	try {

		set data [aws_codebuild_app_service::clone $id]

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