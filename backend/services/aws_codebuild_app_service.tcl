package require logger

source "./database/db.tcl"
source "./support/uuid.tcl"

namespace eval aws_codebuild_app_service {

	variable log
	variable cache
	variable fields

	set cache [dict create]
	set log [logger::init aws_codebuild_app_service] 

	set fields {
		id {id int}
		stack_var_name {stackVarName string}
		version_tag {versionTag string} 
		aws_ecr_repository_name {awsEcrRepositoryName string}
		aws_account_id {awsAccountId string}
		aws_region {awsRegion string}
		aws_url {awsUrl string}
		code_base {codeBase string}
		build_vars {buildVars string}
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
	set aws_codebuild_app [prepare $data]
	dict set aws_codebuild_app created_at [today] 
	
	set rs [db::insert aws_codebuild_apps $aws_codebuild_app]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	return [$rs get_data]
}

proc aws_codebuild_app_service::update {data} {

	set aws_codebuild_app [prepare $data]
	dict set aws_codebuild_app id [dict get $data id] 
	
	set rs [db::update aws_codebuild_apps $aws_codebuild_app]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc aws_codebuild_app_service::all {} {
	variable fields

	set rs [db::all aws_codebuild_apps [dict keys $fields]]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set aws_codebuild_app [rs_to_entity $it]
		lappend results $aws_codebuild_app
	}

	return $results 
}

proc aws_codebuild_app_service::find {id} {
	variable fields

	set rs [db::one aws_codebuild_apps [dict keys $fields] $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]

	if {$data == ""} {
		return ""
	}	

	return [rs_to_entity $data]
}

proc aws_codebuild_app_service::find_all_by_stack {id} {
	variable fields

	set rs [db::where aws_codebuild_apps [dict keys $fields] "stack_id = $id"]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set aws_codebuild_app [rs_to_entity $it]
		lappend results $aws_codebuild_app
	}

	return $results 
}

proc aws_codebuild_app_service::delete {id} {

	set rs [db::delete aws_codebuild_apps $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	
}

proc aws_codebuild_app_service::exists {id} {

	set rs [db::delete aws_codebuild_apps $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set count [lindex $data 0]

	return [expr {$count > 0}]
}

proc aws_codebuild_app_service::rs_to_entity {rs} {
	variable fields

	set index 0
	set aws_codebuild_app [dict create]
	set tpl [dict create]

	dict for {k v} $fields {
		set fieldName [lindex $v 0]
		set fieldType [lindex $v 1]
		set value [lindex $rs $index]

		dict set aws_codebuild_app $fieldName $value
		dict set tpl $fieldName $fieldType

		incr index
	}

	return [dict create data $aws_codebuild_app tpl $tpl]
}