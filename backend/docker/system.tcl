
#!/bin/tclsh

package require logger 0.3
package require json 1.3.3

set log [logger::init system]


proc system_df {} {
	set cmd [list df -BG]
	#TODO: implements
}

proc system_mem {} {
	set cmd [list cat /proc/meminfo]
	#TODO: implements
}

proc service_docker_stop {} {
	set cmd [list sudo service docker stop]
	#TODO: implements
}

proc service_docker_start {} {
	set cmd [list sudo service docker start]
	#TODO: implements
}

proc service_docker_restart {} {
	set stopResult [service_docker_stop]
	set startResutl [service_docker_start]
	#TODO: implements
}