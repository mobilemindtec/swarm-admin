
package require Thread
package require logger

source "support/async.tcl"


namespace eval person_worker {

	variable tbuffer
	variable tbufferNext
	variable log
	variable buffer

	set log [logger::init person_worker]
}

proc person_worker::init {} {

	variable tbuffer
	variable tbufferNext
	variable buffer

	set tbuffer [list]
	set buffer [list]
	set tbufferNext 0

	for {set i 0} {$i < 2} {incr i} {
		
		set tid [thread::create]
		
		lappend tbuffer $tid
		
		create_thread_ctx $tid

		thread::send -async $tid [list init $app::configs]

	}

}	

proc person_worker::dispatch {data} {
	variable tbuffer
	variable tbufferNext

	set tid [lindex $tbuffer $tbufferNext]
	
	thread::send -async $tid [list send $data]
	
	incr tbufferNext
	
	if {$tbufferNext >= [llength $tbuffer]} {
		set tbufferNext 0
	} 	

}

proc person_worker::dispatch_batch {} {
	variable tbuffer
	variable tbufferNext
	variable buffer


	if {[llength $buffer] == 0} {
		return
	}

	set tid [lindex $tbuffer $tbufferNext]
	
	if {$tbufferNext >= [llength $tbuffer]} {
		set tbufferNext 0
	} else {
		incr tbufferNext
	}		

	thread::send -async $tid [list send_batch $buffer]			

	set buffer [list]
}

proc person_worker::create_thread_ctx {tid} {
	thread::send $tid {

		package require logger

		source "database/db.tcl"
		source "support/async.tcl"

		variable buffer 

		set log [logger::init person_worker_thread]
		set buffer [list]

		namespace eval app {
			variable configs
			set configs {}
		}

		proc init {configs} {
			set app::configs $configs
			puts "Consumer thread init"
			pool::init_pool 1
			every 5000 do_insert_buffer

			vwait forever
		}

		proc send {data} {
			variable buffer
			lappend buffer $data
		}

		proc send_batch {data} {
			variable buffer
			foreach it $data {
				lappend buffer $it
			}
		}

	  proc do_insert_buffer {} {
	  	variable buffer
	  	set n [llength $buffer]

			if {$n > 0} {

				set data $buffer
				if {$n > 1500} {
					set data [lrange $buffer 0 1500]
					set buffer [lrange $buffer 1500 end]
				} else {
					set buffer [list]
				}
				

				db::tx { {tx fn buff} {
					
					foreach b $buff {
						$fn $b $tx
					}

				}} insert $data


				
				puts "insert [llength $data] -> done"
				
			}

	  }

		proc insert {data tx} {

			variable log

			set sql {
				insert into people 
					(id, nickname, name, birthday, stack, search) 
					values (?, ?, ?, ?, ?, ?)
			}

			set id [dict get $data id]
			set nickname [dict get $data apelido]
			set name [dict get $data nome]
			set birthday [dict get $data nascimento]
			set stack [dict get $data stack]
			set search "$nickname,$name,$birthday,$stack" 
			set params [list $id $nickname $name $birthday $stack $search]
			set result [db::execute $sql $params $tx]
			
			if {[$result has_error]} {
				${log}::error "insert error: [$result get_error_info]"
				puts "id = $id"
				puts "nickname = $nickname"
				puts "name = $name"
				puts "birthday = $birthday"
				puts "stack = $stack"
			}

		}  
	}
}
