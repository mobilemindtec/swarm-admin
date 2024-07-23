package require logger 0.3

source "./configs/configs.tcl"
source "./services/authenticator_service.tcl"

namespace eval api_authenticator_handler {
	variable log
	set log [logger::init api_authenticator_handler]
}


proc api_authenticator_handler::enabled? {request} {
	set use_auth_code [get_cnf authenticator enabled]
	return [dict create json [dict create enabled $use_auth_code]]
}

proc api_authenticator_handler::pair {request} {
	set use_auth_code [get_cnf authenticator enabled]

	if {$use_auth_code} {
		set html [authenticator_service::pair]
		return [dict create json [dict create html $html]]
	}
	set resp [dict create error true message "authenticator is disabled"]
	return [dict create json $resp statusCode 500]
}