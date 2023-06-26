#!/bin/tclsh

package require logger 0.3

set log [logger::init router]

proc find_route {routes path} {

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

		#if { $rParts != $pParts } {
		#	continue
		#}

		for {set j 0} {$j < $rParts} {incr j} {
			
			if { $j >= $pParts } {
				#next route
				break
			}

			set routePart [lindex $routeParts $j]
			set pathPart [lindex $pathParts $j]

			#${log}::notice "j = $j, routePart = $routePart, pathPart = $pathPart"

			set any false

			if { $routePart == "*" } {
				set any true
			} 

			if { $routePart != $pathPart && ! $any } {

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

			if { [expr $j + 1] == $rParts || $any } {
				set ret  [dict create]
				set dRoute [dict get $routes $route]
				dict set ret route $route
				
				dict set ret handler [dict get $dRoute handler]

				if {[dict exists $dRoute "after"]} {
					dict set ret "after" [dict get $dRoute "after"]				
				} else {
					dict set ret "after" []
				}

				if {[dict exists $dRoute "before"]} {
					dict set ret "before" [dict get $dRoute "before"]
				} else {
					dict set ret "before" []
				}

				dict set ret auth [dict get $dRoute auth]
				dict set ret methods [dict get $dRoute methods]
				dict set ret vars $variables

				${log}::info "found route $path"

				return $ret
			}
		}
	}

	${log}::info "not found route $path"

	return not_found
}
