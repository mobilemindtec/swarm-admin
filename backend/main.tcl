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

app::run


