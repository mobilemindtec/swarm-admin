#!/bin/tclsh


package require tcltest
package require TclCurl

namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./json/json.tcl"
source "./core/httpclient.tcl"
source "./security/jwt.tcl"

set _configs [load_configs]
set server http://localhost:5151
set header {-H "Content-Type: application/json"}

proc login_test {} {
	set auth [dict create username test password test]
	set response [http_post_json "${::server}/login" $auth]
	dict get $response token
}

test login {
	test login
} -body {
	
	set token [login]
	
	token_validate $token

} -result true

cleanupTests