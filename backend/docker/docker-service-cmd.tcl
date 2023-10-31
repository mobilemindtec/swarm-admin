#!/bin/tclsh

package require logger 0.3
package require json 1.3.3

source "./configs/configs.tcl"
source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

namespace eval docker {
	variable log
	set log [logger::init docker-service-cmd]
}


proc docker::service_ls {} {

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

	set results [execute_with_fmt $cmd pformat]

	if {[has_error $results]} {
		return $results
	}

	set data [dict get $results data]
	set columns [list id name image replicas ports]
	return [dict create columns $columns rows $data]		
}

proc docker::service_ps {id} {

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

	set results [execute_with_fmt $cmd pformat]

	if {[has_error $results]} {
		return $results
	}
	set data [dict get $results data]
	set columns [list id name image node desired_state current_state err ports]
	return [dict create columns $columns rows $data]		
}

proc docker::service_rm {serviceName} {
	variable log
	set cmd [list docker service rm $serviceName]
	execute $cmd
} 

proc docker::service_update {serviceName} {
	variable log
	set cmd [list docker service update --force $serviceName]
	execute $cmd
}

proc docker::service_logs_get {serviceName} {
	variable log

	set systemTime [clock seconds]
	set datetime [clock format $systemTime -format %Y%m%d%H%M%S]
	set logsPath [get_cnf docker logs path]

	set fileName docker_service_${serviceName}_${datetime}.log
	set logFile "$logsPath/$fileName"

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
				return [json_error $err]		
			}
		}

	} err] } {
		return [json_error $err]
	}

	return [dict create error false messages [list "link:local:/download/logs/$fileName"] fileName $fileName]

} 

proc docker::service_logs_stream {serviceName follow_stream {tail 100}} {
	set fd [open [list | docker service logs \
									--follow \
									--timestamps \
									--raw \
									--tail $tail \
									$serviceName \
									2>@1]]
	
	set follow $follow_stream
	lappend follow $fd
	
	fconfigure $fd -blocking false -buffering none
	chan event $fd readable $follow
	return $fd
	# [list {*}$follow_stream $fd]

	#proc follow {fd} {
	#	if {[gets $fd line] < 0} {
	#		puts "not to read"
	#	} else {
	#		puts "read $line"
	#	}
	#}

}