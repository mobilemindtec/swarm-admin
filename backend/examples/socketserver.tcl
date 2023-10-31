


global _socketHandler
global _nodes

proc defaultSocketHanlder {chan} {
	puts "defaultSocketHanlder"

}

set _socketHandler defaultSocketHanlder
set _nodes []

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

proc handleServer {fd} {

	global _socketHandler

   if {[eof $fd]} {
        puts "The server closed the connection"
        close $fd
        exit
    } else {
        set data [read $fd]
        if {$data ne ""} {
            puts "Received: $data"
        }
    }
	

}

proc clusterServe {chan addr port} {
	fconfigure $chan -translation auto -buffering line
	fileevent $chan readable [list handleServer $chan]
}

proc runSocketApp {configs} {
	global _socketHandler
	global _nodes

	set nodes []

	if {[dict exists $configs handler]} {
		set _socketHandler [dict get $configs handler]
	}

	if {[dict exists $configs nodes]} {
		set nodes [dict get $configs nodes]
	}

	puts "open socket server on port 5050"

	set socket [socket -server clusterServe 5050 ]

	foreach node $nodes {
		puts "open new connection with $node"
		set chan [socket $node 5050]
		lappend _nodes $chan	
	}
}
