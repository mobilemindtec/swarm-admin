package require logger 0.3

source "./core/router.tcl"

namespace eval httpworker {
	variable workers
	variable log
	variable nextThread

	set log [logger::init httpworker]
	set workers [list]
	set nextWork 0
}

proc httpworker::init {workerCount {current true}} {
	variable workers
	variable log

	${log}::debug "init http with $workerCount workers"

	if {$current} {
		lappend workers current
	}

	for {set i 0} {$i < $workerCount} {incr i} {
		
		set tid [thread::create { thread::wait }]
		
		lappend workers $tid
		
		new_thread_ctx $tid

		thread::send -async $tid [list init $app::configs [router::get_routes]]

	}	
}

proc httpworker::accept {socket addr port} {
	httpworker::_accept $socket $addr $port 
}

proc httpworker::_accept {socket addr port} {
	
	variable workers
	variable nextWork

	set tid [lindex $workers $nextWork]

	if {$tid == "current"} {
		http_server::accept $socket $addr $port
	} else {
		after 0 [list httpworker::transfer_socket $tid $socket $addr $port]  
	}

	incr nextWork
	
	if {$nextWork >= [llength $workers]} {
		set nextWork 0
	} 
}

proc httpworker::transfer_socket {tid socket addr port} {
		thread::transfer $tid $socket
		thread::send -async $tid [list accept $socket $addr $port]	
}

proc httpworker::new_thread_ctx {tid} {

	thread::send $tid {

		package require logger 0.3


		namespace eval app {
			variable configs
			variable routes			
		}
		
		source "./handlers/index.tcl"
		source "./core/httpserver.tcl"
		source "./core/router.tcl"
		source "./workers/person_worker.tcl"
		source "./database/db.tcl"
		source "./core/app.tcl"
		
		proc init {configs routes} {

			puts "init http worker"

			set app::configs $configs
			router::set_routes $routes

			person_worker::init
			pool::init 1

		}

		proc accept {socket addr port} {
			http_server::accept $socket $addr $port
		}


	}

}
