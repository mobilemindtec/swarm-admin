#!/bin/tclsh

# Example websocket server from anonymous user at
# https://core.tcl-lang.org/tcllib/tktview?name=0dd2a66f08

package require logger 0.3
package require websocket

namespace eval websocket_app {

  variable log
  variable Sessions

  set log [logger::init websocket_app]
  set Sessions [dict create]

  ::websocket::loglevel debug
}

proc websocket_app::init {socket} {

  variable log
  ${log}::info "init"
  # 1. declare the (tcp) server-socket as a websocket server
  ::websocket::server $socket
  # 2. register callback

  ::websocket::live $socket / websocket_app::handle
}

proc websocket_app::check_headers {headers} {
  #upvar $headers hdrs  
  if { ![dict exists $headers "  "] } {
    dict set headers "Sec-WebSocket-Protocol" ""    
  }   
  return $headers
}

proc websocket_app::upgrade {serverSocket clientSocket headers} {
  variable log
  
  if {[::websocket::test $serverSocket $clientSocket / $headers]} {
    ${log}::debug "Incoming websocket connection received"
    # 4. upgrade the socket 
    ::websocket::upgrade $clientSocket
  } else {
    close $clientSocket
  }  
}

proc websocket_app::handle {clientSocket typeOfEvent dataReceived} {
  variable log

  set websocket_handler [get_cnf websocket handler]
  set websocket_handler_msg [get_cnf websocket handler_msg]

  if {$typeOfEvent eq "connect" } {
    ${log}::debug "new client connected: $clientSocket"
    session_init $clientSocket              
  }

  if {$websocket_handler eq ""} {
    ${log}::debug "websocket handler not configured"
  } else {
    $websocket_handler $clientSocket $typeOfEvent $dataReceived    
  }

  switch $typeOfEvent {

    text {
      if {$websocket_handler_msg ne ""} {
        $websocket_handler_msg $clientSocket $dataReceived
      }      
    }

    disconnect {
      ${log}::debug "client disconnected: $clientSocket"
      session_destroy $clientSocket                 
    }

    close {
      ${log}::debug "client closed: $clientSocket"      
      session_destroy $clientSocket                 
    }

    timeout {
      ${log}::error "client timeout: $clientSocket"
    }

    error {
      ${log}::error "client error: $clientSocket. $dataReceived"
    }

  }

  #switch $typeOfEvent {
  #  connect {
  #    ${log}::debug "new client connected"
  #    dict set ::Sessions $clientSocket [dict create] 
  #  }
  #  disconnect {
  #    ${log}::debug "client disconnected"
  #    dict remove ::Sessions $clientSocket 
  #    if {$websocket_handler != ""} {
  #      websocket_handler $clientSocket 
  #    }
  #  }
  #  text {
  #      if {$websocket_handler_msg != ""} {
  #        $websocket_handler_msg $clientSocket $dataReceived
  #      }
  #    #::websocket::send $clientSocket text "The server received '$dataReceived'"
  #  }
  #  binary {}
  #  error {
  #    ${log}::error "websocket error: $dataReceived"
  #  }
  #  close { }
  #  timeout {
  #    ${log}::error "websocket timeout" 
  #  }
  #  ping {}
  #  pong {}
  #}

}

proc websocket_app::send_data {clientSocket msgType msg} {
  set data [dict create msgType $msgType msg $msg]
  ::websocket::send $clientSocket text [tcl2json $data]  
}

proc websocket_app::validate_message {data} {
  if {![dict exists $data msgType] || ![dict exists $data msg]} {
    return false
  }  
  return true
}

proc websocket_app::dict_try_get { d k def } {
  if {[dict exists $d $k]} {
    return [dict get $d $k]
  }
  return $def
}

proc websocket_app::clear_session {clientSocket} {
  variable Sessions
  dict remove $Sessions "$clientSocket" 
}

proc websocket_app::session_add {clientSocket k v} {
  variable Sessions
  set session [dict get $Sessions "$clientSocket"]
  dict set session $k $v
  dict set $Sessions "$clientSocket" $session
}

proc websocket_app::session_remove {clientSocket k} {
  variable Sessions
  set session [dict get $Sessions "$clientSocket"]
  set session [dict remove $session $k]
  dict set ::Sessions "$clientSocket" $session
}

proc websocket_app::session_init {clientSocket} {
  variable Sessions
  dict set $Sessions "$clientSocket" [dict create] 
}

proc websocket_app::session_destroy {clientSocket} {
  clear_session $clientSocket     
}

proc websocket_app::try_session_close_fd {clientSocket args} {
  variable log
  variable Sessions

  set session [dict_try_get $Sessions "$clientSocket" [dict create]]

  foreach name $args {

    set fd [dict_try_get $session $name false]

    if {$fd != false} {
      ${log}::debug "close $name $fd"

      if {[catch {
        close $fd
        puts "$name closed"

        session_remove $clientSocket $name
        puts "$name session removed"

      } err]} {
        ${log}::error "error on close file descriptor $name: $err"
      }
      
    } else {
      ${log}::debug "$name not found on session"
    }  

  }
}