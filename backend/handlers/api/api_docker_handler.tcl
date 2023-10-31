
package require logger 0.3


source "./docker/docker.tcl"

set log [logger::init api_handler]


proc docker_service_ls {request} {

	set query [dict get $request query]
	set results [docker::cmd  "service ls"]
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc docker_service_ps {request} {

	set pathVars [dict get $request vars]
	set serviceId [dict get $pathVars id]
	set results [docker::cmd  "service ps" $serviceId]	
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc docker_service_rm {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service rm" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc docker_service_update {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service update" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc docker_service_logs_get {request} {

	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [docker::cmd  "service logs get" $serviceName]	

	set data [dict create data $result]
	return [dict create json $data]
}

proc docker_stack_deploy {request} {

	set pathVars [dict get $request vars]
	set stackId [dict get $pathVars stack]

	set stack [stack_service::find $stackId]

	if {$stack eq ""} {
		return [dict create json [dict create error true message "stack $stackId not found"]]		
	}

	set stackContent [dict get $stack content]
	set stackName [dict get $stack name]
	set apps [aws_codebuild_app_service::find_all_by_stack $stackId]
	
	foreach it $apps {
		set varName [dict get $it stackVarName]
		set version [dict get $it versionTag]
		set stackContent [string map $stackContent [list $varName $version]]				
	}

	set result [docker::cmd  "stack deploy" $stackName $stackContent]

	set data [dict create data $result]
	return [dict create json $data]
}

proc docker_stack_rm {request} {

	set pathVars [dict get $request vars]
	set stackId [dict get $pathVars stack]

	set stack [stack_service::find $stackId]

	if {$stack eq ""} {
		return [dict create json [dict create error true message "stack $stackId not found"]]		
	}

	set stackName [dict get $stack name]

	set result [docker::cmd  "stack rm" $stackName]

	set data [dict create data $result]
	return [dict create json $data]
}