#!/bin/tclsh

package require logger 0.3

source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

namespace eval docker {
	variable log
	set log [logger::init docker-system-cmd]
}

proc docker::system_df {} {
	variable log
	set cmd [list docker system df]
	execute $cmd
} 

proc docker::system_prune {} {
	variable log
	set cmd [list docker system prune -a]
	execute $cmd
} 

proc docker::stats {} {
	variable log
	set cmd [list docker stats]
	execute $cmd
} 