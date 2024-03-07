	#!/bin/tclsh

package require logger 0.3


source "./support/util.tcl"

namespace eval router {

	variable log
	variable routes
	
	set log [logger::init router]
}

proc router::get_uri_query {uri} {
  set parts [split $uri ?]
  set queries [lindex $parts 1]
  set requestQuery [dict create]

  foreach var [split $queries "&"] {
    if { [string trim $var] == "" } {
      continue
    }
    set param [split $var "="]
    set k [lindex $param 0] 
    set v [lindex $param 1]
    dict set requestQuery $k $v 
  }  
  return $requestQuery
}


proc router::extract_route_and_variables {route} {

	set variables {}

	set parts [split $route /]
	set n [llength $parts]
	set newReRoute ""
	
	for {set i 0} {$i < $n} {incr i} {

		set part [lindex $parts $i]

		if {$part == ""} {
			continue
		}

		# if path starts with : is path var
		if {[string match :* $part]} {

			set param ""
			set re ""

			# find path var and regex
			regexp -nocase {:([a-zA-Z_]*\(?/?)(\(.+\))?} $part -> param re

			# empty regex
			if {$re == ""} {
				set re {.+}
			} else {
				# remve ()
				set re [regsub {\(} $re ""]
				set re [regsub {\)} $re ""]								
			}

			set newReRoute "$newReRoute/($re)"

			lappend variables $param $re
		} else {
			# no path var
			set newReRoute "$newReRoute/$part"
		}
	}

	if {[string match {*/\*} $newReRoute]} {
		set newReRoute "^${newReRoute}"
	} else {
		set newReRoute "^${newReRoute}(/?)$"
	}


	return [list $newReRoute $variables]
}

proc router::prepare_route {route routeKey {main false}} {

	variable log

	set routesResuls [list]

	set subRoutes [util::get_def_or_keys $route [] routes]
	set auth [util::get_def_or_keys $route false auth]
	set methods [util::get_def_or_keys $route [] methods]
	set handler [util::get_def_or_keys $route "" handler]
	set after_ [util::get_def_or_keys $route "" "after"]
	set before_ [util::get_def_or_keys $route "" "before"]
	set ws [util::get_def_or_keys $route false ws]
	set path [dict get $route path]

	dict set route auth $auth
	dict set route methods $methods
	dict set route handler $handler
	dict set route "after" $after_
	dict set route "before" $before_
	dict set route ws $ws

	set routePath $routeKey$path
	#puts "routePath = $routePath"

	#${log}::debug "route = $routeKey, subs =([llength $subRoutes])"
	
	if {[llength $subRoutes] > 0} {
	

		if {"$handler" != ""} {
			dict set route path $routePath
			lappend routesResuls $route
		}

		foreach sRoute $subRoutes {
			set rKey [dict get $sRoute path]


			set auth0 [util::get_def_or_keys $sRoute $auth auth]
			set methods0 [util::get_def_or_keys $sRoute $methods methods]
			set handler0 [util::get_def_or_keys $sRoute $handler handler]
			set after0 [util::get_def_or_keys $sRoute $after_ "after"]
			set before0 [util::get_def_or_keys $sRoute $before_ "before"]
			set ws0 [util::get_def_or_keys $sRoute $ws ws]

			#puts "==> $methods0, $routePath$rKey"

			dict set sRoute auth $auth0
			dict set sRoute methods $methods0			
			dict set sRoute handler $handler0
			dict set sRoute "after" $after0
			dict set sRoute "before" $before0
			dict set sRoute ws $ws0
			#dict set sRoute path "$routeFullPath$rKey"

			set rds [prepare_route $sRoute $routePath]

			foreach r $rds {
				lappend routesResuls $r
			}			
		} 

	} else {
		
		set result [extract_route_and_variables $routePath]
		set rePath [lindex $result 0]
		set variables [lindex $result 1]

		# remove end / if need, and add regex to do / optional
		if {[string match -nocase */ $routePath]} {
			#set rePath "[string range $rePath 0 end-1](/?)$"
			set routePath [string range $routePath 0 end-1]
		} 

		dict set route path $routePath
		dict set route repath $rePath
		dict set route variables $variables

		lappend routesResuls $route
	}

	return $routesResuls
}

proc router::init {items} {

	variable routes

	set n [llength $items]	
	set allRoutes [list]

	foreach route $items {
		set path [dict get $route path]
		set results [prepare_route $route "" true]
		foreach r $results {			
			lappend allRoutes $r
		}
	}	

	set routes $allRoutes
}

proc router::get_routes {} {
	variable routes
	return $routes
}

proc router::set_routes {r} {
	variable routes
	set routes $r
}


proc router::print {} {
	variable log
	variable routes

	${log}::info ":: routes"
	foreach route $routes {
		${log}::info ": [string toupper [dict get $route methods]] [dict get $route path] -> [dict get $route repath]"
	}
	${log}::info "::"	
}

proc router::match {reqPath method} {

	variable routes
	variable log

	set variables [dict create]
	
	foreach routeDict $routes {
		
		set routePath [dict get $routeDict path]
		set routeRePath [dict get $routeDict repath]
		set variables [dict get $routeDict variables]
		set query [dict create]

		# if if route match
		set results [regexp -nocase -all -inline $routeRePath $reqPath]
		if {[llength $results] == 0} {
			#puts "not match $reqPath == $routeRePath"
			continue
		}

		#puts "route match $reqPath => $routePath"

		# check method
		set methods [dict get $routeDict methods]
		if {![has_route_method $methods $method]} {
			continue
		}

		# result = matchVal + [path1Val, path1Val, ...]

		set n [llength $variables]
		set vars {}

		for {set i 0} {$i < $n} {incr i} {
			set item [lindex $variables $i]
			set pathVarName [lindex $item 0]
			set pathVar [lindex $results [expr {$i + 1}]]
			lappend vars $pathVarName $pathVar
		}


		set ret  [dict create]
		dict set ret route $routeDict
		dict set ret handler [dict get $routeDict handler]
		dict set ret "after" [dict get $routeDict "after"]				
		dict set ret "before" [dict get $routeDict "before"]
		dict set ret auth [dict get $routeDict auth]
		dict set ret methods $methods 
		dict set ret vars $vars
		dict set ret ws [dict get $routeDict ws]

		return $ret		
	}

	return not_found
}

proc router::has_route_method {methods method} {
	foreach mtdo $methods {
		if {[string toupper $method] == [string toupper $mtdo]} {
			return true
		}
	}
	return false
}