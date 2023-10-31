
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