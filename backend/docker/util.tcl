

proc format_image {image} {
	set imageParts [split $image :]
	set ilen [llength $imageParts]	
	return [lindex $imageParts [expr $ilen - 2]]:[lindex $imageParts [expr $ilen - 1]]	
}