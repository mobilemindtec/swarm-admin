#!/bin/tclsh

package require logger 0.3

set log [logger::init main]


source "./core/app.tcl"
source "./core/router.tcl"
source "./handlers/index.tcl"


app::init
router::print

#person_worker::init

app::run

