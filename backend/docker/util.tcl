

proc format_image {image} {
	set imageParts [split $image :]
	set ilen [llength $imageParts]	
	return [lindex $imageParts [expr $ilen - 2]]:[lindex $imageParts [expr $ilen - 1]]	
}

proc has_error {results} {
	return [dict exists $results error] && [dict get $results error]  
}

proc json_error {err} {
	set lines [lsearch -all -inline -not -exact [split $err \n] {}]
	return [dict create error true messages $lines]
}