package require logger 0.3

source "./services/aws_build_service.tcl"

variable log
set log [logger::init aws_build_handler]


# inicia um build para um app
proc aws_build_start {request} {
	variable log
	set id [dict get $request vars id] 
	set response [dict create error false messages ""]

	${log}::debug "aws_build_start $id"
	
	try {

		set result [aws_build_service::codebuild_start $id]

		if {$result == ""} {
			return [response::json_not_found]
		}

		if {[dict exists $result error]} {
			return [response::json_server_error $result]	
		}

		return [response::json_data_ok $result]

	} on error err {
		${log}::error $err
		return [response::json_error $err]		
	}
}

# lista os builds de um app
proc aws_build_list {request} {
	variable log
	set id [dict get $request vars id]

	set app [aws_codebuild_app_service::find $id]

	if {$app == ""} {
		return [response::json_not_found]
	}

	try {

		set result [aws_build_service::list_by_app_id $id]		
		return [response::json_data_ok $result true]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}

}

# bisca infomações de um build
proc aws_build_get {request} {
	variable log
	set id [dict get $request vars id]

	try {

		set build [aws_build_service::find $id]

		if {$build == ""} {
			return [response::json_not_found]
		}

		return [response::json_data_ok $build]
		
	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}
}

# atualiza informações de um build
proc aws_build_update {request} {
	variable log
	set id [dict get $request body id]

	try {

		set build [aws_build_service::codebuild_update $id]

		if {$build == ""} {
			return [response::json_not_found]
		}

		if {[dict exists $build error]} {
			return [response::json_error [dict get $build messages]]
		}
		
		return [response::json_data_ok $build]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}	

}

# para um build em andamento
proc aws_build_stop {request} {
	variable log
	set id [dict get $request vars id]

	try {

		set build [aws_build_service::codebuild_stop $id]

		if {$build == ""} {
			return [response::json_not_found]
		}

		if {[dict exists $build error]} {
			return [response::json_error [dict get $build messages]]
		}

		return [response::json_data_ok $build]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}	
}

# deleta um build
proc aws_build_delete {request} {
	variable log
	set id [dict get $request body id]

	try {


		if {![aws_build_service::exists $id]} {
			return [response::json_not_found]
		}

		aws_build_service::delete $id


		return [response::json_ok]

	} on error err {
		${log}::error $err
		return [response::json_error $err]
	}	
}