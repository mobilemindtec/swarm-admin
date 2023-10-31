#!/bin/tclsh


package require tcltest
namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./core/router.tcl"

namespace eval app {
	variable configs
	variable routes
	
	set configs [load_configs]
	set routes [router::prepare_routes [get_cnf routes]]
} 

test router-test {
	test route not found
} -body {
	set r [router::find_route "/api/customer/test/1" get]
	return $r
} -result not_found

test router-test-stacks-get {
	test route get stacks
} -body {
	set r [router::find_route "/mngr/stack" get]
	return [expr {$r != "not_found"}]
} -result 1

test router-test-stack-get {
	test route get stack
} -body {
	set r [router::find_route "/mngr/stack/1" get]
	return [expr {$r != "not_found"}]
} -result 1

test router-test-stack-post {
	test route port stack
} -body {
	set r [router::find_route "/mngr/stack" post]
	return [expr {$r != "not_found"}]
} -result 1

test router-test-stack-put {
	test route put stack
} -body {
	set r [router::find_route "/mngr/stack" put]
	return [expr {$r != "not_found"}]
} -result 1

test router-test-stack-delete {
	test route delete stack
} -body {
	set r [router::find_route "/mngr/stack" delete]
	return [expr {$r != "not_found"}]
} -result 1

test router-test-found {
	test route found
} -body {
	set r [router::find_route "/app/login" get]
	return [expr {$r != "not_found"}]
} -result 1


cleanupTests