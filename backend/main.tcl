#!/bin/tclsh

package require logger 0.3


set log [logger::init main]




source "./core/app.tcl"
source "./core/router.tcl"
source "./handlers/index.tcl"
source "./jobs/jobs.tcl"


app::init

#person_worker::init

jobs::schedule

set environment dev

if {[info exists ::env(ENV)]} {
	set environment $::env(ENV)
}
puts "::> .............................."
puts "::> Run App Swarm Admin On \[$environment\] Mode"
puts "::> .............................."

app::run
