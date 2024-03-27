
source "./services/aws_build_service.tcl"
source "./services/aws_codebuild_app_service.tcl"

namespace eval job_update_apps_in_building {
	variable log
	set log [logger::init job_update_apps_in_building]
}

proc job_update_apps_in_building::update {} {

	variable log

	${log}::debug "run job update_apps_in_building"

	try {
		set apps [aws_codebuild_app_service::all_building]
	} on error err {
		${log}::debug "error on search buildings: $err"
		return	
	}

	${log}::debug "[llength $apps] apps is on building"

	if {[llength $apps] == 0} {
		return
	}

	foreach app $apps {
		set appId [dict get $app id]
		set builds [aws_build_service::list_by_app_id_and_buiding $id]

		foreach build $builds {

			set buildId [dict get $build id]
			set buildUpdated [aws_build_service::codebuild_update $buildId]

			if {$buildUpdated == ""} {
				${log}::error "no build found to id $buildId"
			}
		}
	}	
}

proc job_update_apps_in_building::schedule {} {
	after 10000 job_update_apps_in_building::run
}

proc job_update_apps_in_building::run {} {

	variable log

	try {
		job_update_apps_in_building::update
	} on error err {
		${log}::debug "error run job update: $err"
	}

	after 10000 job_update_apps_in_building::run
}