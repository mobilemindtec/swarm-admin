
source "./json/json.tcl"

proc load_configs {} {	
	set fd [open "./configs/configs.json" r]
	set content [read $fd]
	set configs [json2dict $content]
	close $fd	
	return $configs
}

proc get_config {configs def args} {

	set curr $configs	
	foreach k $args {

		if { ![dict exists $curr $k] } {
			return $def
		}

		set curr [dict get $curr $k]
	}

	return $curr
}

proc get_cnf {args} {
	global _configs
	get_config $_configs "" {*}$args
}