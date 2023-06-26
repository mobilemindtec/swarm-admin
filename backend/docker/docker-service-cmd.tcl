#!/bin/tclsh

package require logger 0.3
package require json 1.3.3

source "./configs/configs.tcl"
source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

set log [logger::init docker-service-cmd]

proc exec_docker_service_ls {} {

	variable log
	set cmd [list \
				docker \
				service ls \
				--format \
				"{{.ID}},{{.Name}},{{.Image}},{{.Replicas}},{{.Ports}}"]

	proc pformat {line} {
		set rows [split $line ,] 	
		set data {}
		dict set data id [string trim [lindex $rows 0]]
		dict set data name [string trim [lindex $rows 1]]
		dict set data image [format_image [string trim [lindex $rows 2]]]
		dict set data replicas [string trim [lindex $rows 3]]
		dict set data ports [string trim [lindex $rows 4]]	
		return $data	
	}

	set results [docker_execute_with_fmt $cmd pformat]

	if {[dict exists $results error]} {
		return $results
	}

	return [dict create columns [list id name image replicas ports] rows $results]		
}

proc exec_docker_service_ps {id} {

	variable log
	set cmd [list \
				docker \
				service \
				ps $id \
				--no-trunc \
				--format \
				"{{.ID}},{{.Name}},{{.Image}},{{.Node}},{{.DesiredState}},{{.CurrentState}},{{.Error}},{{.Ports}}"]

	proc pformat {line} {
		set rows [split $line ,]		
		set data {}	
		dict set data id [string trim [lindex $rows 0]]
		dict set data name [string trim [lindex $rows 1]]
		dict set data image [format_image [string trim [lindex $rows 2]]]	
		dict set data node [string trim [lindex $rows 3]]	
		dict set data desiredState [string trim [lindex $rows 4]]
		dict set data currentState [string trim [lindex $rows 5]]
		dict set data err [string trim [lindex $rows 6]]
		dict set data ports [string trim [lindex $rows 7]]
		return $data	
	}

	set results [docker_execute_with_fmt $cmd pformat]

	if {[dict exists $results error]} {
		return $results
	}

	return [dict create columns [list id name image node desired_state current_state err ports] rows $results]		
}

proc exec_docker_service_rm {serviceName} {
	variable log
	set cmd [list docker service rm $serviceName]
	docker_execute $cmd
} 

proc exec_docker_service_update {serviceName} {
	variable log
	set cmd [list docker service update --force $serviceName]
	docker_execute $cmd
}

proc exec_docker_service_get_logs {serviceName} {
	variable log

	set systemTime [clock seconds]
	set datetime [clock format $systemTime -format %Y%m%d%H%M%S]
	set logsPath [get_cnf docker logs path]

	set logFile "${logsPath}/docker_service_${serviceName}_${datetime}.log"

	set cmdGetIds [list \
									docker service ps \
									$serviceName \
									| grep Running \
									| awk  {{print $1}}]
	
	if { [ catch {
		set result [exec {*}$cmdGetIds]
		set ids [lsearch -all -inline -not -exact [split $result \n] {}]

		foreach id $ids {
			set cmdGetLogs [list \
												docker service logs \
												$id >> $logFile]
			if { [ catch {
				exec {*}$cmdGetLogs
			} err ] } {
				return [dict create error true message "get logs: $err"]		
			}
		}

	} err] } {
		return [dict create error true message "get container ids: $err"]
	}

	return [dict create error false path $logFile]

} 