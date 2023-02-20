
package require logger 0.3
package require json 1.3.3

set log [logger::init main]

proc normalizeLine {line} {
	set map [dict create "  " "-"]
  set newline [string map $map $line]
  set map [dict create " " "+"]
  set newline [string map $map $newline]
  set map [dict create "-" " "]
  set newline [string map $map $newline]  	
  return $newline
}

proc removePlus {newline} {
  set map [dict create "+" " "]
  set newline [string map $map $newline]  	
  set newline [string trim $newline]
  set newline [regsub -all {[\r\n]+$} $newline ""]
  return $newline
}

proc execDockerCmd {cmd args} {

	variable log

	${log}::debug "execute docker cmd = $cmd"

	switch $cmd {
	 	"service ls" {
			dockerCmd_ls
		}
		"service ps" {
			dockerServiceCmd_ps $args
		}
		default {
			${log}::debug "CMD $cmd not found"
		}
	}
}

proc dockerCmdList {cmd cb} {
	variable log
	${log}::debug "dockerCmdList"
	set lines [split [exec {*}$cmd] "\n"] 
	set results []
	${log}::debug "lines = $lines"
	set lines [lrange $lines 1 [llength $lines]]

	foreach line $lines {
		set data [$cb $line]
		lappend results $data
		#puts "$id $name $replicated $replicatedCount "		
	}

	return $results		
}

proc dockerCmd_ls {} {

	variable log
	set cmd [list docker service ls]

	proc pformat {line} {
		set newline [normalizeLine $line]
		lassign $newline id name replicated replicatedCount 	
		set data {}
		dict set data id [removePlus $id]
		dict set data name [removePlus $name]
		dict set data replicas [removePlus $replicatedCount]	
		return $data	
	}

	set results [dockerCmdList $cmd pformat]

	#${log}::debug " results = $results"
	return [dict create columns [list id name replicas] rows $results]		
}

proc dockerServiceCmd_ps {srvName} {

	variable log
	set cmd [list docker service ps $srvName]

	proc pformat {line} {

		set newline [normalizeLine $line]		
		lassign $newline id name image node desiredState   currentState err ports 	
		lappend data id [removePlus $id]
		lappend data name [removePlus $name]
		lappend data node [removePlus $node]	
		lappend data desired_state [removePlus $desiredState]
		lappend data current_state [removePlus $currentState]
		lappend data err [removePlus $err]
		return $data	
	}

	set results [dockerCmdList $cmd pformat]

	${log}::debug " results = $results"
	return [dict create columns [list id name node desired_state current_state err] rows $results]		
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