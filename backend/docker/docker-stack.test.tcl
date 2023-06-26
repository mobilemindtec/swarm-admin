#!/bin/tclsh


package require tcltest
namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./docker/docker.tcl"

set _configs [load_configs]

test docker-stack-deploy-test {
  docker stack deploy fail
} -body {
    
    set result [exec_docker_cmd "stack deploy" stackdemo]
    llength $result

} -result 4

test docker-stack-rm-test {
  docker stack rm fail
} -body {
    
    set result [exec_docker_cmd "stack rm" stackdemo]
    expr {[llength $result] > 0}

} -result 1