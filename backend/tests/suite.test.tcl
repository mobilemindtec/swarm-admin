#!/bin/tclsh


package require tcltest
package require TclCurl

namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./json/json.tcl"
source "./core/httpclient.tcl"
source "./security/jwt.tcl"

set server http://localhost:5151
set header {-H "Content-Type: application/json"}

namespace eval app {
	variable configs
	
	set configs [load_configs]

} 


proc login_test {} {
	set auth [dict create username test password test]
	set response [http_client::post_json "${::server}/login" $auth]
	return [dict get $response token]
}

test login {
	test login
} -body {
	
	set token [login_test]
	
	jwt::validate $token

} -result true

cleanupTests