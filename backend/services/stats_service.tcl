package require logger

source "./database/db.tcl"
source "./support/uuid.tcl"

namespace eval stats_service {

	variable log
	variable cache

	set cache [dict create]
	set log [logger::init stats_service] 

}


proc stats_service::validate {data} {


	
}

proc stats_service::today {{format "%Y-%m-%d %H:%M:%S"}} {
	set now [clock seconds]
	return [clock format $now -format $format] 
}

proc stats_service::prepare {data} {
	set stat [dict create]
	dict set stat description [dict get $data description]
	dict set stat aws_s3_uri [dict get $data aws_s3_uri]
	dict set stat updated_at [today]
	return $stat
}


proc stats_service::save {data} {
	set stat [prepare $data]
	dict set stat created_at [today] 
	
	set rs [db::insert stats $stat]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	return [$rs get_data]
}

proc stats_service::update {data} {
	set stat [prepare $data]
	dict set stat id [dict get $data id] 
	
	set rs [db::update stats $stat]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}
}

proc stats_service::all {} {

	set rs [db::all stats [list id description aws_s3_uri created_at updated_at]]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set results [list]

	foreach it $data {
		set stat [rs_to_entity $it]
		lappend results $stat
	}

	return $results 
}

proc stats_service::find {id} {

	set rs [db::first stats [list id description aws_s3_uri created_at updated_at] $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]

	if {$data == ""} {
		return ""
	}	

	return [rs_to_entity $data]
}


proc stats_service::delete {id} {

	set rs [db::delete stats $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	
}

proc stats_service::exists {id} {

	set rs [db::delete stats $id]

	if {[$rs has_error]} {
		error [$rs get_error_info]
	}	

	set data [$rs get_data]
	set count [lindex $data 0]

	return [expr {$count > 0}]
}

proc stats_service::report {stat} {

	set uri [dict get $stat aws_s3_uri]
	set filename [lindex [split $$uri /] end]
	set dest /tmp/$filename
	set cmd [list aws s3 cp $uri $dest]
	
	exec {*}$cmd

	set fd [open $dest]
	set content [read $fd]
	close $fd
	return $content	
}

proc stats_service::rs_to_entity {rs} {

	set id [lindex $rs 0]

	#puts "ID = $id, int? [string is integer -strict $id]"

	set stat [dict create]
	dict set stat id $id
	dict set stat description [lindex $rs 1]
	dict set stat aws_s3_uri [lindex $rs 2]
	dict set stat createdAt [lindex $rs 3]
	dict set stat updatedAt [lindex $rs 4]	
	return $stat
}