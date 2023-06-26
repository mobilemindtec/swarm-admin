#!/bin/tclsh

package require logger 0.3

source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

set log [logger::init docker-cmd]

proc exec_docker_stack_deploy {stackName} {
	global _configs
	variable log

	set path [get_cnf docker stack path]
	set ext [get_cnf docker stack ext]

	${log}::debug "deploy stack path: $path"

	set cmd [list docker stack deploy \
						--with-registry-auth \
						-c $path/$stackName.$ext \
						$stackName]
	docker_execute $cmd
}

proc exec_docker_stack_rm {stackName} {
	variable log
	set cmd [list docker stack rm $stackName]
	docker_execute $cmd
}

