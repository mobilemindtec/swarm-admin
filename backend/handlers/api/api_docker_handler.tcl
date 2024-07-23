
package require logger 0.3


source "./docker/docker.tcl"

namespace eval api_docker_handler {
	variable log
	set log [logger::init api_docker_handler]
}

proc api_docker_handler::service_ls {request} {

	set query [dict get $request query]
	set results [docker::cmd  "service ls"]
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc api_docker_handler::service_ps {request} {

	set pathVars [dict get $request vars]
	set serviceId [dict get $pathVars id]
	set results [docker::cmd  "service ps" $serviceId]	
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc api_docker_handler::service_rm {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service rm" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc api_docker_handler::service_update {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service update" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc api_docker_handler::service_logs_get {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service logs get" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc api_docker_handler::stack_deploy {request} {

	set pathVars [dict get $request vars]
	set stackName [dict get $pathVars stack_name]
	set stack [stack_service::find_by_name $stackName]

	if {$stack eq ""} {
		return [dict create json [dict create error true message "stack $stackName not found"]]		
	}

	set stackContent [dict get $stack content]
	set stackName [dict get $stack name]
	set stackId [dict get $stack id]
	set apps [aws_codebuild_app_service::find_all_by_stack_id $stackId false]

	puts "apps for stake [llength $apps]"
	
	foreach it $apps {
		set varName [dict get $it stackVarName]
		set version [dict get $it versionTag]
		set stackContent [string map [list $varName $version] $stackContent]				
	}

	set result [docker::cmd  "stack deploy" $stackName $stackContent]

	set data [dict create data $result]
	return [dict create json $data]
}

proc api_docker_handler::stack_rm {request} {


	set pathVars [dict get $request vars]
	set stackName [dict get $pathVars stack_name]

	set stack [stack_service::find_by_name $stackName]

	if {$stack eq ""} {
		return [dict create json [dict create error true message "stack $stackName not found"]]		
	}

	set stackName [dict get $stack name]

	set result [docker::cmd  "stack rm" $stackName]

	set data [dict create data $result]
	return [dict create json $data]
}