
package require logger 0.3

source "./services/aws_codebuild_app_service.tcl"

variable log
set log [logger::init aws_codebuild_app_handler]

proc aws_codebuild_app_index {request} {
	variable log
	
	try {

		set result [aws_codebuild_app_service::all]	
		return [response::json_data_ok $result true]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
}

proc aws_codebuild_app_save {request} {
	variable log
	
	set body [dict get $request body]

	try {

		set result [aws_codebuild_app_service::save $body]
		return [response::json_data_ok $result]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}	
}

proc aws_codebuild_app_update {request} {
	variable log
	
	set body [dict get $request body]

	try {

		aws_codebuild_app_service::update $body
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}	
}

proc aws_codebuild_app_edit {request} {
	variable log
	
	set id [dict get $request vars id]

	try {

		set data [aws_codebuild_app_service::find $id]

		if {$data == ""} {
			return [response::json_not_found]
		}

		return [response::json_data_ok $data]					
				
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}

proc aws_codebuild_app_delete {request} {
	variable log
	
	set id [dict get $request body id]

	try {
		
		set exists [aws_codebuild_app_service::exists $id]

		if {!$exists} {
			return [response::json_not_found]
		}

		aws_codebuild_app_service::delete $id
		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}


proc aws_codebuild_app_clone {request} {
	variable log
	

	set id [dict get $request vars id]


	try {

		set data [aws_codebuild_app_service::clone $id]

		if {$data == ""} {
			return [response::json_not_found]
		} 

		return [response::json_data_ok $data]
				
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
	
}


