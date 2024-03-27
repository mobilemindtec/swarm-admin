
source "./jobs/job_update_apps_in_building.tcl"
source "./jobs/job_server_stats.tcl"
source "./jobs/job_docker_stats.tcl"

namespace eval jobs {
	variable log
	set log [logger::init jobs]
}


proc jobs::schedule {} {
	#job_server_stats::schedule
	#job_docker_stats::schedule
	#job_update_apps_in_building::schedule
}

