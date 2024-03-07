
namespace eval util {

}

proc util::try_get {d args} {

	set curr $d	
	foreach k $args {

		if { ![dict exists $curr $k] } {
			return ""
		}

		set curr [dict get $curr $k]
	}

	return $curr
}

proc util::get_def_or_keys {d defVal args} {

	set next $d

	foreach k $args {
		if {[dict exists $next $k]} {
			set next [dict get $next $k]
		} else {
			return $defVal
		}
	}

	return $next
}