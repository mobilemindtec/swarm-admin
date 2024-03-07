#!/bin/tclsh

package require logger 0.3

source "./configs/configs.tcl"
source "./docker/util.tcl"

namespace eval docker {
	variable log
	set log [logger::init docker-execute]
}


proc docker::execute_with_fmt {cmd cb args} {
	variable log

	${log}::debug $cmd
	set lines ""

	try {
		set lines [split [exec {*}$cmd] "\n"] 
	} on error err {
		${log}::error $err
		return [json_error $err]
	}
	
	set results [list]
	#${log}::debug "lines = $lines"
	#set lines [lrange $lines 1 [llength $lines]]

	foreach line $lines {
		#${log}::debug "line $line"
		set data [$cb $line]
		lappend results $data
	}

	return [dict create error false data $results]		
}

proc docker::execute {cmd} {
	variable log

	${log}::debug $cmd
	set result ""

	try {
		set result [split [exec {*}$cmd] "\n"] 
	} on error err {
		${log}::error $err
		return [json_error $err]
	}
	set lines [lsearch -all -inline -not -exact $result {}]
	return [dict create error false messages $lines]
}
