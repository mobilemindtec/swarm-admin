
package require logger 0.3
package require json 1.3.3

set log [logger::init main]

proc normalize_line {line} {
	set map [dict create "  " "-"]
  set newline [string map $map $line]
  set map [dict create " " "+"]
  set newline [string map $map $newline]
  set map [dict create "-" " "]
  set newline [string map $map $newline]  	
  return $newline
}

proc remove_plus {newline} {
  set map [dict create "+" " "]
  set newline [string map $map $newline]  	
  set newline [string trim $newline]
  set newline [regsub -all {[\r\n]+$} $newline ""]
  return $newline
}

proc exec_docker_cmd {cmd args} {

	variable log

	${log}::debug "execute docker cmd = $cmd"

	switch $cmd {
	 	"service ls" {
			exec_docker_service_ls
		}
		"service ps" {
			exec_docker_service_ps $args
		}
		default {
			${log}::debug "CMD $cmd not found"
		}
	}
}

proc exec_docker_cmd_fmt {cmd cb} {
	variable log
	${log}::debug "exec_docker_cmd_fmt"
	set lines [split [exec {*}$cmd] "\n"] 
	set results []
	#${log}::debug "lines = $lines"
	set lines [lrange $lines 1 [llength $lines]]

	foreach line $lines {
		set data [$cb $line]
		lappend results $data
		#puts "$id $name $replicated $replicatedCount "		
	}

	return $results		
}

proc exec_docker_service_ls {} {

	variable log
	set cmd [list \
						docker \
						service ls \
						--format \
						"{{.ID}},{{.Name}},{{.Image}},{{.Replicas}},{{.Ports}}"]

	proc pformat {line} {
		puts "line = $line"
		#set newline [normalize_line $line]
		#lassign $newline id name replicated replicatedCount
		set rows [split $line ,] 	
		set data {}
		dict set data id [string trim [lindex $rows 0]]
		dict set data name [string trim [lindex $rows 1]]
		dict set data image [format_image [string trim [lindex $rows 2]]]
		dict set data replicas [string trim [lindex $rows 3]]
		dict set data ports [string trim [lindex $rows 4]]	

		#dict set data id [remove_plus $id]
		#dict set data name [remove_plus $name]
		#dict set data replicas [remove_plus $replicatedCount]	
		return $data	
	}

	set results [exec_docker_cmd_fmt $cmd pformat]

	#${log}::debug " results = $results"
	return [dict create columns [list id name image replicas ports] rows $results]		
}

proc format_image {image} {
	set imageParts [split $image :]
	set ilen [llength $imageParts]	
	return [lindex $imageParts [expr $ilen - 2]]:[lindex $imageParts [expr $ilen - 1]]	
}

proc exec_docker_service_ps {id} {

	variable log
	set cmd [list \
						docker \
						service \
						ps $id \
						--no-trunc \
						--format \
						"{{.ID}},{{.Name}},{{.Image}},{{.Node}},{{.DesiredState}},{{.CurrentState}},{{.Error}},{{.Ports}}"]

	proc pformat {line} {
		#set newline [normalize_line $line]
		set rows [split $line ,]		
		#lassign $newline id name image node desiredState   currentState err ports 	
		set data {}	
		dict set data id [string trim [lindex $rows 0]]
		dict set data name [string trim [lindex $rows 1]]
		dict set data image [format_image [string trim [lindex $rows 2]]]	
		dict set data node [string trim [lindex $rows 3]]	
		dict set data desiredState [string trim [lindex $rows 4]]
		dict set data currentState [string trim [lindex $rows 5]]
		dict set data err [string trim [lindex $rows 6]]
		dict set data ports [string trim [lindex $rows 7]]

		#dict set data id [remove_plus $id]
		#dict set data name [remove_plus $name]
		#dict set data image [remove_plus $image]	
		#dict set data node [remove_plus $node]	
		#dict set data desiredState [remove_plus $desiredState]
		#dict set data currentState [remove_plus $currentState]
		#dict set data err [remove_plus $err]
		return $data	
	}

	set results [exec_docker_cmd_fmt $cmd pformat]

	#${log}::debug " results = $results"
	return [dict create columns [list id name image node desired_state current_state err ports] rows $results]		
}


proc writeLogs {chan} {
	# sudo apt install tcllib
	#package require json 1.3.3

	variable log
	set ContainerName "payments.webapp"

	set imageID [exec docker ps -q --filter ancestor=$ContainerName]

	${log}::debug "Image ID = $imageID"

	if { $imageID == "" } {
	  ${log}::debug "docker is not live"
	  return 
	}

	#set fd [list [exec docker logs -f --tail 50 --follow ${imageID} > stdout]]

	set result [lindex [::json::json2dict [exec docker inspect $imageID]] 0]
	set logPath [dict get $result LogPath]
	#set path [dict getnull $inspectJson "Id"]
	#set channel [open |[list [exec docker logs --timestamp --tail 50 --follow ${imageID}]] r+]

	#puts [tcl::unsupported::representation $inspectJson] 

	puts $logPath

	puts [file tail $logPath]


	set logs [open $logPath r]
	seek $logs 0 end
	for {} {true} {after 300} {
	  set line [read $logs]
	  if {$line != ""} {
	    set jsonObj [::json::many-json2dict $line]
	    for {set i 0} {$i < [llength $jsonObj]} {incr i} {
	      set item [lindex $jsonObj $i]
	      set logValue [dict get $item log]
	      set logTime [dict get $item "time"]
	      puts -nonewline "$logTime: $logValue"  
	      puts -nonewline $chan "$logTime: $logValue"
	    }
	  } 
	}	
}