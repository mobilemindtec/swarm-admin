
package require logger 0.3

source "./configs/configs.tcl"
source "./core/httpserver.tcl"
source "./core/websocket.tcl"
source "./database/db.tcl"
source "./core/httpworker.tcl"
source "./support/async.tcl"


namespace eval app {
	variable log
	variable configs

	set log [logger::init app]
}


proc app::init_routes {} {

	variable configs
	variable ServerSocket

	set configs [load_configs]
	router::init [dict get $configs routes]	
}

proc app::init {} {
	init_routes	
}

proc app::run {} {

	variable log
	variable configs
	variable ServerSocket

  set port [get_cnf_or_def 5151 server port]

  ${log}::info "http server started on http://localhost:$port"

  #test_route

  set workers [expr {[get_cnf_or_def 1 server workers]*1}]
  
  if {$workers > 1} {
  	httpworker::init $workers
  	set socket [socket -server httpworker::accept [expr $port * 1]]  
  } else {
  	pool::init 10
  	set socket [socket -server http_server::accept [expr $port * 1]]  
  }


  set ServerSocket $socket
  
  websocket_app::init $socket
  
  vwait forever
}

proc test_route {} {
	set re ^/api/aws/codebuild/app/(\[0-9]+)(/?)$
	set rs [regexp -nocase -all -inline $re /api/aws/codebuild/app/111]
	puts "result = $rs"
}