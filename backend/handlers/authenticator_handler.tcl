source "./configs/configs.tcl"
source "./services/authenticator_service.tcl"


proc authenticator-enabled? {request} {
	set use_auth_code [get_cnf authenticator enabled]
	return [dict create json [dict create enabled $use_auth_code]]
}

proc authenticator-pair {request} {
	set use_auth_code [get_cnf authenticator enabled]

	if {$use_auth_code} {
		set html [authenticator_service::pair]
		return [dict create json [dict create html $html]]
	}
	set resp [dict create error true message "authenticator is disabled"]
	return [dict create json $resp statusCode 500]
}