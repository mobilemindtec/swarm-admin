
 proc new_uuid {} {
     ## Try and get a string unique to this host.
     set str [info hostname]$::tcl_platform(machine)$::tcl_platform(os)
     binary scan $str h* hex

     set    uuid [format %2.2x [clock seconds]]
     append uuid -[string range [format %2.2x [clock clicks]] 0 3]
     append uuid -[string range [format %2.2x [clock clicks]] 2 5]
     append uuid -[string range [format %2.2x [clock clicks]] 4 end]
     append uuid -[string range $hex 0 11]

     return $uuid
 }