#!/bin/tclsh	


set fd [open [list | docker service logs \
								--follow \
								--timestamps \
								--raw \
								--tail 100 \
								gym_auth \
								2>@1]]
chan event $fd readable [list follow $fd]

proc follow {fd} {
	if {[gets $fd line] < 0} {
		puts "not to read"
	} else {
		puts "read $line"
	}
}

vwait forever