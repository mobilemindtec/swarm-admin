#!/bin/tclsh

package require logger 0.3

set log [logger::init main]

proc findRoute {routes path} {

	variable log

	set n [dict size $routes]
	set variables [dict create]
	set routeKeys [ dict keys $routes]

	#${log}::notice "routes = $routes, $n, find by $path"
	#${log}::notice "routes keys = $routeKeys"

	for {set i 0} {$i < $n} {incr i} {
		
		set route [lindex $routeKeys $i]

		#${log}::notice "route = $route"

		set routeParts [split $route /]
		set pathParts [split $path /]
		set rParts [llength $routeParts]
		set pParts [llength $pathParts]

		#${log}::notice "route parts $routeParts, $rParts"
		#${log}::notice "path parts $pathParts, $pParts"

		if { $rParts != $pParts } {
			continue
		}

		for {set j 0} {$j < $rParts} {incr j} {
			
			if { $j >= $pParts } {
				#next route
				break
			}

			set routePart [lindex $routeParts $j]
			set pathPart [lindex $pathParts $j]

			#${log}::notice "j = $j, routePart = $routePart, pathPart = $pathPart"


			if { $routePart != $pathPart } {

				if { [string match {:*} $routePart] } {
					set varName [string map { : "" } $routePart ]
					#puts "set route var $varName=$pathPart" 
					lappend variables $varName $pathPart
					#next route part
					#continue
				} else {
					break
				}
			}

			if { [expr $j + 1] == $rParts } {
				set ret  [dict create]
				dict set ret route $route
				dict set ret handler [dict get $routes $route]
				dict set ret vars $variables

				${log}::info "found route $path"

				return $ret
			}
		}
	}

	${log}::info "not found route $path"

	return not_found
}
