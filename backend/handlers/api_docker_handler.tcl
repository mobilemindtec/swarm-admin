
package require logger 0.3

set log [logger::init api_handler]


source "./docker/docker.tcl"

proc docker_service_ls {request} {

	variable log

	${log}::debug "docker_service_ls"

	set cmd "ls"
	set query [dict get $request query]
	set results [exec_docker_cmd  "service ls"]
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc docker_service_ps {request} {

	set cmd "ps"
	set pathVars [dict get $request vars]
	set serviceId [dict get $pathVars id]
	set results [exec_docker_cmd  "service ps" $serviceId]	
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	set data [dict create data $rows]
	return [dict create json $data]
}

proc docker_service_rm {request} {
	set cmd "service rm"
	set pathVars [dict get $request vars]
	set serviceName [dict get $pathVars service_name]
	set result [exec_docker_cmd  "service rm" $serviceName]	
	set data [dict create data $result]
	return [dict create json $data]
}


