#!/bin/tclsh

package require logger 0.3
package require json 1.3.3

source "./configs/configs.tcl"
source "./docker/util.tcl"
source "./docker/docker-service-cmd.tcl"
source "./docker/docker-cmd.tcl"
source "./docker/docker-stack-cmd.tcl"
source "./docker/docker-system-cmd.tcl"

set log [logger::init docker]


proc exec_docker_cmd {cmd args} {

	variable log

	${log}::debug "execute docker cmd = $cmd"

	switch $cmd {
	 	"service ls" {
			return [exec_docker_service_ls]
		}
		"service ps" {
			return [exec_docker_service_ps {*}$args]
		}
		"service rm" {
			return [exec_docker_service_rm {*}$args]
		}
		"service update" {
			return [exec_docker_service_update {*}$args]
		}
		"service get logs" {
			return [exec_docker_service_get_logs {*}$args]
		}
		"ps" {
			return [exec_docker_ps]
		}		
		"stop" {
			return [exec_docker_stop {*}$args]
		}		
		"aws login" {
			return [exec_docker_aws_login]
		}
		"system df" {
			return [exec_docker_system_df]
		}
		"system prune" {
			return [exec_docker_system_prune]
		}
		"system stats" {
			return [exec_docker_system_stats]
		}
		"stack deploy" {
			return [exec_docker_stack_deploy {*}$args]
		}
		"stack rm" {
			return [exec_docker_stack_rm {*}$args]
		}
		default {
			${log}::debug "CMD $cmd not found"
			return [dict create error true message "command $cmd not found"]
		}
	}
}

proc writeLogs {chan} {
	# sudo apt install tcllib
	#package require json 1.3.3

	variable log
	set ContainerName "payments.webapp"

	set imageID [exec docker ps -q --filter ancestor=$ContainerName]

	${log}::debug "Image ID = $imageID"

	if { $imageID == "" } {
	  ${log}::debug "docker is not live"
	  return 
	}

	#set fd [list [exec docker logs -f --tail 50 --follow ${imageID} > stdout]]

	set result [lindex [::json::json2dict [exec docker inspect $imageID]] 0]
	set logPath [dict get $result LogPath]
	#set path [dict getnull $inspectJson "Id"]
	#set channel [open |[list [exec docker logs --timestamp --tail 50 --follow ${imageID}]] r+]

	#puts [tcl::unsupported::representation $inspectJson] 

	puts $logPath

	puts [file tail $logPath]


	set logs [open $logPath r]
	seek $logs 0 end
	for {} {true} {after 300} {
	  set line [read $logs]
	  if {$line != ""} {
	    set jsonObj [::json::many-json2dict $line]
	    for {set i 0} {$i < [llength $jsonObj]} {incr i} {
	      set item [lindex $jsonObj $i]
	      set logValue [dict get $item log]
	      set logTime [dict get $item "time"]
	      puts -nonewline "$logTime: $logValue"  
	      puts -nonewline $chan "$logTime: $logValue"
	    }
	  } 
	}	
}