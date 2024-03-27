#!/bin/tclsh

package require tcltest
namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./database/db.tcl"
source "./services/authenticator_service.tcl"

namespace eval app {
  variable configs
  
  set configs [load_configs]
} 


test authenticator-pair-test {
	authenticator pair failed
} -body {
	
    set r [authenticator_service::pair]
    puts "RESULT = $r"
    return 0

} -result 0

test authenticator-authenticate-test {
	authenticator authenticate failed
} -body {
	
    set r [authenticator_service::authenticate "207791"]
    puts "RESULT = $r"
    return 0

} -result 0