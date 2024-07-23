package require logger 0.3

source "./configs/configs.tcl"

namespace eval api_servers_handler {
	variable log
	set log [logger::init api_servers_handler]
}


proc api_servers_handler::list {} {

	set servers [get_cnf servers]
	set curr ""

	if {[info exists ::env(HOSTNAME)]} {
		set curr $::env(HOSTNAME)
		set curr [split $curr .]
		set curr [lindex $curr 0]
	}

	set resp {}

	dict for {host server} $servers {
		set item [dict create hostname $host server $server]
		if {$host == $curr} {
			dict set current true
		} else {
			dict set current false
		}
		lappend resp $item
	}

	return [dict create json $resp]

}