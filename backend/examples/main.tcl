#!/bin/tclsh

package require httpd

set ::DEBUG 0
set ::clay::debug $::DEBUG
set TESTDIR [file dirname [file normalize [info script]]]

proc DEBUG args {
    if {!$::DEBUG} return
    uplevel 1 $args
}

clay::define ::httpd::server {
    method log args {}

    method TemplateSearch page {
        
        switch $page {
            redirect {
                return {300 Redirect}
            }
            notfound {
                return {404 Not Found}
            }
            internal_error {
                return {500 Server Internal Error}
            }
            default {
                puts "page = $page"
            }
        }
    }


    ::DEBUG method debug args {
        puts stderr $args
    }

    ::DEBUG method log args {
        puts stdout $args
    }
}

clay::define handler {
    method content {} {
        puts "handler"
        puts [my request get path]
    }
}

::httpd::server create appmain port 10001 doc_root $::TESTDIR
appmain plugin basic_url ::httpd::plugin.dict_dispatch
appmain uri add * /* [list mixin {reply handler}]

#cron::main



proc http_serve {chan addr port} {

    set uuid [::clay::uuid::short]
    set coro [coroutine ::httpd::coro::$uuid {*}[list get_reply $uuid $chan]]
    chan event $chan readable $coro

    #variable reply
    #set reply($chan) {}    
    #chan configure $chan -translation {auto crlf} -blocking 0 -buffering line -buffersize 4096
    #chan event $chan readable [list get_reply $chan]



}

proc get_reply {uuid chan} {
    puts "get_reply"
    set max 0
    yield [info coroutine]
    chan configure $chan -translation auto -blocking 0 -buffering full -buffersize 4096

    set data [read $chan]
    puts "data = $data"

   

    puts $chan "HTTP/1.0 200"
    puts $chan "Content-Type: plain/text"  
    puts $chan ""
    close $chan

        #while 1 {
    #    set line [gets $chan]
    #    puts "line=$line"
    #    if {[eof $chan]} {
    #        break
    #    }        
    #    set max [incr $max]
    #    if { $max >= 50 } {
    #        break
    #    }
    #}

    #variable buffer
    #set data [read $chan]
    #puts "data = $data"
    #append buffer($chan) $data
    #if {[eof $chan]} {
    #    chan event $chan readable {}
    #    set reply($chan) $buffer($chan)
    #    puts "data receive ok = $buffer"
    #    unset buffer($chan)
    #} else {
    #    puts "not eof"
    #}
}

proc reply {chan} {
	puts "reply!"
}

set sk [socket -server http_serve 5151]
vwait forever  


