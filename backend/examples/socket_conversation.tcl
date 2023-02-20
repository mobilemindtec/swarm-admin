
#!/bin/tclsh

 proc uniqkey { } {
     set key   [ expr { pow(2,31) + [ clock clicks ] } ]
     set key   [ string range $key end-8 end-3 ]
     set key   [ clock seconds ]$key
     return $key
 }

 proc sleep { ms } {
     set uniq [ uniqkey ]
     set ::__sleep__tmp__$uniq 0
     after $ms set ::__sleep__tmp__$uniq 1
     vwait ::__sleep__tmp__$uniq
     unset ::__sleep__tmp__$uniq
 }

proc clusterServeReceive {chan} {

	if {[eof $chan]} {
		puts "client lost connection"
	} else {
		set line [gets $chan]

		if { $chan ne "" } {
			puts "server received: $line"

			puts $chan "Im reveive you message!!"
			flush $chan
		}
	}
}

proc clusterServe {chan addr port} {
	fconfigure $chan -translation auto -buffering line
	fileevent $chan readable [list clusterServeReceive $chan]

	#set line [gets $chan]
	#puts "server received: $line"
	#close $chan

	# state machine
}

set server [socket -server clusterServe 5050]

set chans []

set servers [ list localhost ]

foreach srv $servers {
	set chan [socket $srv 5050]
	lappend chans $chan	
}

puts "chans $chans"

proc sendMessage msg {
	global chans
	puts "send message $msg"
	foreach chan $chans {
		puts $chan $msg
		flush $chan
		sleep 1000
		puts "result: [gets $chan]"	
	}
}


foreach var [list 1 2 3 4 5 6 7 8 9 10] {
	sendMessage "hey!! $var"
	sleep 2000
}

vwait forever