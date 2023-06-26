#!/bin/tclsh

package require logger 0.3

source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

set log [logger::init docker-system-cmd]

proc exec_docker_system_df {} {
	variable log
	set cmd [list docker system df]
	docker_execute $cmd
} 

proc exec_docker_system_prune {} {
	variable log
	set cmd [list docker system prune -a]
	docker_execute $cmd
} 

proc exec_docker_stats {} {
	variable log
	set cmd [list docker stats]
	docker_execute $cmd
} 