
source "./json/json.tcl"

proc remove_comments {contents} {
	set content ""
	set lines [split $contents \n]
	foreach line $lines {
		if {[string match //* [string trim $line]]} {
			continue
		}
		set content "$content$line\n"
	}

	return $content
}

proc load_configs {} {	
	set fd [open "./configs/configs.json" r]
	set contents [remove_comments [read $fd]]
	set configs [json2dict $contents]
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
	get_config $app::configs "" {*}$args
}

proc get_cnf_or_def {def args} {
	get_config $app::configs $def {*}$args
}