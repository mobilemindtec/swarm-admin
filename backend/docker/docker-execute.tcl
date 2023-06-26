#!/bin/tclsh

package require logger 0.3

source "./configs/configs.tcl"


proc docker_execute_with_fmt {cmd cb args} {
	variable log

	${log}::debug "docker_execute $cmd"
	set lines ""

	if {[catch {
		set lines [split [exec {*}$cmd] "\n"] 
	} err]} {
		${log}::error "docker_execute: $err"
		return [dict create error true message $err]
	}
	
	set results []
	#${log}::debug "lines = $lines"
	#set lines [lrange $lines 1 [llength $lines]]

	foreach line $lines {
		#${log}::debug "line $line"
		set data [$cb $line]
		lappend results $data
	}

	return $results		
}

proc docker_execute {cmd} {
	variable log

	${log}::debug "docker_execute $cmd"
	set result ""

	if {[catch {
		set result [split [exec {*}$cmd] "\n"] 
	} err]} {
		${log}::error "docker_execute: $err"
		return [dict create error true message $err]
	}

	set lines [lsearch -all -inline -not -exact [split $result \n] {}]
	return [dict create error false message $lines]
}
