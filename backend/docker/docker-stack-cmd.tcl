#!/bin/tclsh

package require logger 0.3

source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

namespace eval docker {
	variable log
	set log [logger::init docker-stack-cmd]
}


proc docker::stack_deploy {stackName stackContent} {
	variable log


	set path [get_cnf docker stack path]
	set ext [get_cnf docker stack ext]
	set stackPath "${path}/${stackName}.${ext}"
	try {
		set fd [open $stackPath w]
		puts $fd $stackContent
		flush $fd
		close $fd
	} on error err {
		return [json_error "error on create stack file: $err"]
	}

	${log}::debug "deploy stack path: $path"

	set cmd [list docker stack deploy \
						--with-registry-auth \
						-c $stackPath \
						$stackName]
	execute $cmd
}

proc docker::stack_rm {stackName} {
	variable log
	set cmd [list docker stack rm $stackName]
	execute $cmd
}

