
namespace eval aws {
	variable log
	set log [logger::init aws]
}

proc aws::date_format {date} {
	set date [lindex [split $date .] 0]
	set date [clock scan $date -format "%Y-%m-%dT%H:%M:%S"] 
	return [clock format $date -format "%Y-%m-%d %H:%M:%S"]
}


proc aws::get_build_id {result} {
	return [dict get $result build id]
}


proc aws::get_build_info {result} {
	set builds [dict get $result builds]
	set build [lindex $builds 0]

	set groupName [dict get $build logs groupName]
	set streamName [dict get $build logs streamName]
	set deepLink [dict get $build logs deepLink]
	set startTime [dict get $build startTime]
	
	if {[dict exists $build endTime]} {
		set endTime [date_format [dict get $build endTime]]
	} else {
		set endTime null
	}

	set currentPhase [dict get $build currentPhase]
	set buildStatus [dict get $build buildStatus]

	set result [dict create]

	dict set result logsGroupName $groupName
	dict set result logsStreamName $streamName
	dict set result logsDeepLink $deepLink

	dict set result startTime [date_format $startTime]
	dict set result endTime $endTime
	dict set result currentPhase $currentPhase
	dict set result buildStatus $buildStatus	

	return $result
}

proc aws::start_build {projectName} {

	variable log
	
	set cmd [list aws \
						codebuild \
						start-build \
						--project-name \
						$projectName]

	try {
		set result [exec {*}$cmd] 	 

		#puts $result

	} on error err {
		${log}::error $err
		return [json_error $err]
	}	

	return [json2dict $result]
} 

proc aws::stop_build {buildId} {

	variable log

	set cmd [list aws \
						codebuild \
						stop-build \
						--id $buildId]
	try {
		set result [exec {*}$cmd] 	 		
	} on error err {
		${log}::error $err
		return [json_error $err]
	}	

	return [json2dict $result]
}

proc aws::get_build {buildId} {

	variable log

	set cmd [list aws \
						codebuild \
						batch-get-builds \
						--ids $buildId]

	try {
		set result [exec {*}$cmd] 	
		puts $result 
	} on error err {
		${log}::error $err
		return [json_error $err]
	}	

	return [json2dict $result]
}


proc aws::get_build_logs_stream {groupName streamName followStream} {
	
	variable log

	#puts "groupName = $groupName"
	#puts "streamName = $streamName"


	set follow $followStream

	try {

		set fd [open [list | aws logs tail \
							$groupName \
							--follow \
							--log-stream-names $streamName \
							2>@1]]

		lappend follow $fd ; # file descriptor
		lappend follow "" ; # log lines
		lappend follow "" ; # error

		
		fconfigure $fd -blocking false -buffering none
		chan event $fd readable $follow
		return [dict create error false fd $fd]

	} on error err {
		${log}::error $err

		lappend follow "" ; # file descriptor
		lappend follow "" ; # log lines
		lappend follow $err ; # error
		{*}$follow

	}	

}

proc aws::get_build_logs {groupName streamName followStream} {
	
	variable log

	#puts "groupName = $groupName"
	#puts "streamName = $streamName"

	set follow $followStream	

	try {


		set cmd [list aws \
									logs \
									get-log-events \
									--log-group-name $groupName \
									--log-stream-name $streamName \
									--start-from-head \
									2>@1] 	 

		set result [exec {*}$cmd]

		set jsonData [json2dict $result]

		set events [dict get $jsonData events]
		set results [list]

		foreach event $events {
			set timestamp [dict get $event timestamp]
			set message [dict get $event message]
			lappend results $message  
		}

		
		lappend follow ""
		lappend follow [lreverse $results]
		lappend follow ""
	
		{*}$follow

		return [dict create error false]		


	} on error err {
		${log}::error $err
		
		lappend follow "" ; # file descriptor
		lappend follow "" ; # log lines
		lappend follow $err ; # error
		{*}$follow

	}	

}


proc aws::list-builds {projectName} {
	
	variable log

	set cmd [list aws \
						codebuild \
						list-builds-for-project \
						--project-name \
						$projectName]

	try {
		set result [exec {*}$cmd] 	 
	} on error err {
		${log}::error $err
		return [json_error $err]
	}	

	return [json2dict $result]	
}

proc aws::delete_build {id} {
	variable log

	set cmd [list aws \
						codebuild \
						delete-build-batch \
						--id \
						$id]

	try {
		set result [exec {*}$cmd] 	 
	} on error err {
		${log}::error $err
		return [json_error $err]
	}	

	return [json2dict $result]	
}