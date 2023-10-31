#!/bin/tclsh


package require tcltest
namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./docker/docker.tcl"

set _configs [load_configs]



# docker service
test docker-service-ls-test {
	docker service ls fail
} -body {
	
    set result [docker::cmd "service ls"]
    set cols [dict get $result columns]
	
    set dictSize [dict size $result]
    set colSize [llength $cols]

    list $dictSize $colSize

} -result [list 2 5]

test docker-service-ps-test {
	docker service ps fail
} -body {
	
    set result [docker::cmd "service ps" stackdemo_redis]
    set cols [dict get $result columns]
	
    set dictSize [dict size $result]
    set colSize [llength $cols]

    list $dictSize $colSize

} -result [list 2 8]

test docker-service-ps-fail-test {
	docker service ps should be fail
} -body {
	
    set result [docker::cmd "service ps" stackdemo_not_found]    
    
    list [dict get $result error] [dict get $result message]

} -result [list true "no such service: stackdemo_not_found"]

test docker-service-rm-test {
  docker service rm fail
} -body {
    
  set result [docker::cmd "service rm" stackdemo_web]
  dict get $result error      
    
} -result false

test docker-service-update-test {
  docker service update fail
} -body {
    
  set result [docker::cmd "service update" stackdemo_redis]
  dict get $result error      
    
} -result false

test docker-service-get-logs-test {
  docker service get logs fail
} -body {
    
  set result [docker::cmd "service get logs" stackdemo_redis]

  puts "result = $result"

  dict get $result error      
    
} -result false


# docker

test docker-ps-test {
  docker ps fail
} -body {
    
    set result [docker::cmd "ps"]
    set cols [dict get $result columns]
  
    set dictSize [dict size $result]
    set colSize [llength $cols]

    list $dictSize $colSize

} -result [list 2 6]

test docker-stop-test {
  docker stop fail
} -body {
    

    set cmd [list docker ps | grep stackdemo_redis | awk {{print $1}}]
    
    set containerId ""

    if { [catch {
      set containerId [exec {*}$cmd]
    } err]} {
      puts "error: $err"
      expr {true}
    } else {
      set result [docker::cmd "stop" $containerId]
      dict get $result error      
    }
} -result false




cleanupTests