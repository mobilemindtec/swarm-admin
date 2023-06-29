#!/bin/tclsh


package require tcltest
namespace import ::tcltest::*

source "./router.tcl"

proc fnRouteHandlerDummy {} {}

test router-test {
	test route not found
} -body {
	
	set routes [dict create]
	dict set routes "/api/customer" fnRouteHandlerDummy
	dict set routes "/api/customer/:id" fnRouteHandlerDummy

	return [findRoute $routes "/api/customer/test/1"]

} -result not_found

test router-test-found {
	test route not found
} -body {
	
	set routes [dict create]
	dict set routes "/api/customer" fnRouteHandlerDummy
	dict set routes "/api/customer/:id" fnRouteHandlerDummy

	set rName "/api/customer"

	set result [findRoute $routes $rName]

	if { $result == "not_found" } {
		return not_found
	} else {

		set f1 [expr {[dict get $result route] == $rName}]

		return $f1
	}


} -result 1

test router-test-foun-path-param {
	test route not found
} -body {
	
	set routes [dict create]
	dict set routes "/api/customer" fnRouteHandlerDummy
	dict set routes "/api/customer/:id" fnRouteHandlerDummy

	set rName "/api/customer/aa1"

	set result [findRoute $routes $rName]

	if { $result == "not_found" } {
		return not_found
	} else {

		set foundRouteName [dict get $result route]
		set foundRouteVars [dict get $result vars]

		set f1 [expr {$foundRouteName == $rName}]
		set f2 [expr {[dict size $foundRouteVars] == 1}]
		set f3 [expr {[dict get $foundRouteVars id] == "aa1"}]

		return $f1 && $f2 && $f3
	}


} -result 1

cleanupTests