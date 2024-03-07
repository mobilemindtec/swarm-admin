package require logger

source "./database/db.tcl"
source "./support/uuid.tcl"

namespace eval aws_codebuild_app_service {

	variable log
	variable cache
	variable fields
	variable tableName 

	set cache [dict create]
	set log [logger::init aws_codebuild_app_service] 
	set tableName aws_codebuild_apps

	set fields {
		id {id int}
		stack_var_name {stackVarName string}
		version_tag {versionTag string} 
		aws_ecr_repository_name {awsEcrRepositoryName string}
		aws_account_id {awsAccountId string}
		aws_region {awsRegion string}
		aws_url {awsUrl string}
		aws_project_name {awsProjectName string}
		building {building boolean}
		code_base {codeBase string}
		build_vars {buildVars string}
		last_build_at {lastBuildAt string}
		stack_id {stackId int}
		created_at {createdAt string}
		updated_at {updatedAt string}
	}

}


proc aws_codebuild_app_service::validate {data} {
	
}

proc aws_codebuild_app_service::today {{format "%Y-%m-%d %H:%M:%S"}} {
	set now [clock seconds]
	return [clock format $now -format $format] 
}

proc aws_codebuild_app_service::prepare {data} {
	variable fields
	set aws_codebuild_app [dict create]

	dict for { k v } $fields {
		
		set fieldName [lindex $v 0]
		
		if {[dict exists $data $fieldName]} {
			dict set aws_codebuild_app $k [dict get $data $fieldName]
		} 
	}

	dict set aws_codebuild_app updated_at [today]

	return $aws_codebuild_app
}


proc aws_codebuild_app_service::save {data} {

	variable tableName

	set entity [prepare $data]
	dict set entity created_at [today] 
	dict set entity lastBuildAt null
	
	set rs [db::insert $tableName $entity]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	return [$rs get_data]
}

proc aws_codebuild_app_service::clone {id} {
	set data [find $id false]

	if {$data == ""} {
		return ""
	} 

	set data [dict remove $data id createdAt updatedAt lastBuildAt]
	set repo [dict get $data awsEcrRepositoryName]

	dict set data awsEcrRepositoryName "$repo (cloned)"  

	return [save $data]
}

proc aws_codebuild_app_service::update {data} {

	variable tableName

	set entity [prepare $data]
	dict set entity id [dict get $data id] 

	if {[dict get $entity last_build_at] eq ""} {
		dict set entity last_build_at null
	}
	
	set rs [db::update $tableName $entity]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc aws_codebuild_app_service::all {} {
	variable fields
	variable tableName

	set rs [db::all $tableName [dict keys $fields]]

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

proc aws_codebuild_app_service::all_building {} {
	variable fields
	variable tableName

	set rs [db::where $tableName [dict keys $fields] "building = ?" true]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set entity [rs_to_entity $it false]
		lappend results $entity
	}

	return $results 
}


proc aws_codebuild_app_service::find {id {tpl true} {raw false}} {
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

proc aws_codebuild_app_service::find_all_by_stack_id {id {tpl true} {raw false}} {
	variable fields
	variable tableName

	set rs [db::where $tableName [dict keys $fields] "stack_id = ?" $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set entity ""

		if {$raw} {
			set entity $it
		} else {
			set entity [rs_to_entity $it $tpl]
		}

		lappend results $entity
	}

	return $results 
}

proc aws_codebuild_app_service::delete {id} {
	variable tableName
	set rs [db::delete $tableName $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	
}

proc aws_codebuild_app_service::exists {id} {
	variable tableName
	set rs [db::delete $tableName $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set count [lindex $data 0]

	return [expr {$count > 0}]
}

proc aws_codebuild_app_service::rs_to_entity {rs {tpl true}} {
	variable fields

	set index 0
	set entity [dict create]
	set template [dict create]

	dict for {k v} $fields {
		set fieldName [lindex $v 0]
		set fieldType [lindex $v 1]
		set value [lindex $rs $index]

		dict set entity $fieldName $value
		dict set template $fieldName $fieldType

		incr index
	}

	if {$tpl} {
		return [dict create data $entity tpl $template]
	}

	return $entity
}