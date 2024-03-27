
package require logger 0.3

set log [logger::init login_handler]


source "./security/jwt.tcl"
source "./configs/configs.tcl"
source "./services/authenticator_service.tcl"


proc auth_token {request} {

	variable log

	set auth [dict get $request auth]

	if {!$auth} {
		return [dict create next $request]	
	}

	${log}::debug "execute auth_token"

	set headers [dict get $request headers]

	if {![dict exists $headers "authorization"]} {
		return [dict create json [dict create error "invalid token"] statusCode 401]
	}

	set token [dict get $headers "authorization"]


	if {![string match {Bearer *} $token]} {
		return [dict create json [dict create error "invalid token"] statusCode 401]
	}

	set token [string trim [lindex [split $token " "] 1]]

	set valid [jwt::validate $token]

	if {!$valid} {
		return [dict create json [dict create error "invalid token"] statusCode 401]	
	}

	return [dict create next $request]
}

proc auth {request} {
	variable log

	${log}::debug "execute login"

	set use_auth_code [get_cnf authenticator enabled]
	set body [dict get $request body]

	if {![dict exists $body username]} {
		return [dict create json [dict create error "username is required"] statusCode 401]
	}

	if {![dict exists $body password]} {
		return [dict create json [dict create error "password is required"] statusCode 401]
	}

	if {$use_auth_code} {
		if {![dict exists $body code]} {
			return [dict create json [dict create error "code is required"] statusCode 401]
		}
	}

	set username [get_cnf_or_def "" credentials username]
	set password [get_cnf_or_def "" credentials password]


	if { $username != [dict get $body username]} {
		return [dict create json [dict create error "invalid username or password"] statusCode 401]
	}

	if { $password != [dict get $body password]} {
		return [dict create json [dict create error "invalid username or password"] statusCode 401]
	}


	if {$use_auth_code} {
		set code [dict get $body code]

		try {
			set authenticated [authenticator_service::authenticate $code]
			if {$authenticated} {
				return [dict create json [jwt::token]]
			} else {
				return [dict create json [dict create error "invalid code"] statusCode 401]
			}
		} on error err {
			set resp [dict create error true message $err]
			return [dict create json $resp statusCode 500]		
		}
	}

	return [dict create json [jwt::token]]
}
