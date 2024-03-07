
source "./aws/aws.tcl"

namespace eval aws_build_service {

	variable log
	variable fields
	variable tableName

	set tableName aws_codebuild_app_builds
	set log [logger::init aws_build_service] 

	set fields {
		id {id int}
		aws_codebuild_app_id {awsCodebuildAppId int}
		build_id {buildId string}
		logs_group_name {logsGroupName string}
		logs_strem_name {logsStreamName string}
		logs_deep_link {logsDeepLink string}
		start_time {startTime string}
		end_time {endTime string}
		current_phase {currentPhase string}
		build_status {buildStatus string}
		app_version_tag {appVersionTag string}		
		created_at {createdAt string}
		updated_at {updatedAt string}
	}

}

proc aws_build_service::today {{format "%Y-%m-%d %H:%M:%S"}} {
	set now [clock seconds]
	return [clock format $now -format $format] 
}

proc aws_build_service::prepare {data} {
	variable fields
	set build [dict create]

	dict for { k v } $fields {
		
		set fieldName [lindex $v 0]
		
		if {[dict exists $data $fieldName]} {
			dict set build $k [dict get $data $fieldName]
		} 
	}

	dict set build updated_at [today]

	return $build
}

proc aws_build_service::rs_to_entity {rs {tpl true}} {
	variable fields

	set index 0
	set build [dict create]
	set template [dict create]

	dict for {k v} $fields {
		set fieldName [lindex $v 0]
		set fieldType [lindex $v 1]
		set value [lindex $rs $index]

		dict set build $fieldName $value
		dict set template $fieldName $fieldType

		incr index
	}

	if {$tpl} {
		return [dict create data $build tpl $template]
	}

	return $build
}


proc aws_build_service::save {data} {
	variable tableName
	set entity [prepare $data]
	dict set entity created_at [today] 

	set rs [db::insert $tableName $entity]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set saved [$rs get_data]
	return [find [dict get $saved id]]
}


proc aws_build_service::update {data} {
	variable tableName
	set entity [prepare $data]
	dict set entity id [dict get $data id] 
	
	set rs [db::update $tableName $entity]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc aws_build_service::delete {id} {
	variable tableName
	
	set rs [db::delete $tableName $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc aws_build_service::list_by_app_id {appId} {
	variable fields
	variable tableName

	set rs [db::where $tableName [dict keys $fields] "aws_codebuild_app_id = ?" $appId {orderBy {id desc} limit 10}]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set entity [rs_to_entity $it]
		lappend results $entity
	}

	return $results 
}

proc aws_build_service::list_by_app_id_and_buiding {appId} {
	variable fields
	variable tableName

	set rs [db::where $tableName [dict keys $fields] "aws_codebuild_app_id = ? and current_phase <> ?" [list $appId COMPLETED]]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set entity [rs_to_entity $it]
		lappend results $entity
	}

	return $results 
}

proc aws_build_service::find {id {tpl true} {raw false}} {
	variable fields
	variable tableName

	set rs [db::first $tableName [dict keys $fields] $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]

	if {$data == ""} {
		return ""
	}	

	if {$raw} {
		return $data
	}

	if {$tpl} {
		return [rs_to_entity $data]		
	}

	return [rs_to_entity $data false]
}

proc aws_build_service::delete {id} {
	variable tableName

	set rs [db::delete $tableName $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	
}

proc aws_build_service::exists {id} {
	variable tableName
	
	set rs [db::delete $tableName $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set count [lindex $data 0]

	return [expr {$count > 0}]
}

proc aws_build_service::codebuild_log_stream {id followStream} {

	set entity [find $id false]

	if {$entity == ""} {
		return $entity
	}

	set buildId [dict get $entity buildId]
	set currentPhase [dict get $entity currentPhase]
	set groupName [dict get $entity logsGroupName]
	set streamName [dict get $entity logsStreamName]

	if {$currentPhase eq "COMPLETED"} {
		return [aws::get_build_logs $groupName $streamName $followStream]		
	}


	return [aws::get_build_logs_stream $groupName $streamName $followStream]
}

proc aws_build_service::create_new_build {app buildId buildInfo} {

	variable tableName

	set data $buildInfo
	dict set data buildId $buildId
	dict set data awsCodebuildAppId [dict get $app id]
	
	return [save $data]
}

proc aws_build_service::codebuild_update_info {entity buildInfo} {

	dict for {k v} $buildInfo {
		dict set entity $k $v
	}

	return [update $entity]
}

proc aws_build_service::codebuild_update {id} {

	set entity [find $id false]

	if {$entity == ""} {
		return ""
	}

	set appId [dict get $entity awsCodebuildAppId]
	set app [aws_codebuild_app_service::find $appId false]

	set buildId [dict get $entity buildId]
	set build [aws::get_build $buildId]

	if {[dict exists $build error]} {
		return $build
	}

	set buildInfo [aws::get_build_info $build]
	
	set result [codebuild_update_info $entity $buildInfo]	

	if {[dict exists $result error]} {
		return $result
	}

	if {[dict get $app building]} {

		set currentPhase [dict get $buildInfo currentPhase]
		set buildStatus [dict get $buildInfo buildStatus]

		if {$currentPhase == "COMPLETED"} {
			dict set app building false
			dict set app versionTag [dict get $entity appVersionTag]
			dict set app lastBuildAt [today]
			aws_codebuild_app_service::update $app
		}
	}

	return [find $id]

}

proc aws_build_service::codebuild_start {appId} {
	set app [aws_codebuild_app_service::find $appId false]

	if {$app == ""} {
		return ""
	}

	if {[dict get $app building]} {
		return {error true message "app is on building"}
	}

	set awsProjectName [dict get $app awsProjectName]
	set version [dict get $app versionTag]

	set currVersion [expr {double(round(100*$version))/100}]

	set newVersion [expr {$currVersion + 0.01}]




	set result [aws::start_build $awsProjectName]

	if {[dict exists $result error]} {
		return $result
	}

	set buildId [aws::get_build_id $result]

	set build [aws::get_build $buildId]

	if {[dict exists $build error]} {
		return $build
	}

	set buildInfo [aws::get_build_info $build]

	dict set buildInfo appVersionTag $newVersion

	set result [create_new_build $app $buildId $buildInfo]

	if {![dict exists $result error]} {
		dict set app building true
		aws_codebuild_app_service::update $app
	}

	return $result
}

proc aws_build_service::codebuild_stop {id} {
	set entity [find $id false]

	if {$entity == ""} {
		return ""
	}

	set buildId [dict get $entity buildId]

	set result [aws::stop_build $buildId]

	if {[dict exists $result error]} {
		return $result
	}

	return [codebuild_update $id]

}

