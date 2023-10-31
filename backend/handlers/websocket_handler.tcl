
package require logger 0.3
package require websocket

set log [logger::init websocket_handler]

source "./json/json.tcl"
source "./docker/docker-service-cmd.tcl"
source "./core/websocket.tcl"


proc websocket {request} {
	# default action
	return [dict create tpl "websocket.html"]
}

proc websocket_handler {clientSocket typeOfEvent dataReceived} {
  variable log

  ${log}::debug "websocket_handler"

  switch $typeOfEvent {
    disconnect {
      websocket_app::try_session_close_fd $clientSocket fd
    }
    text {
      handle_message $clientSocket $dataReceived
    }
  }
}

proc handle_message {clientSocket dataReceived} {

  variable log

  ${log}::debug "handle_message"

  set data [json2dict $dataReceived]

  if {![websocket_app::validate_message $data]} {
    websocket_app::send_data $clientSocket error "invalid message format. use {msgType, msg}"
    close $clientSocket
    return
  }

  set msgType [dict get $data msgType]
  set msg [dict get $data msg]

  switch $msgType {

      logStart {
        set serviceName [websocket_app::dict_try_get $msg serviceName none]        
        set tail [websocket_app::dict_try_get $msg tail 100]        
        set fd [docker::service_logs_stream $serviceName [list log_stream $clientSocket] $tail]

        if {$serviceName eq "none"} {
          websocket_app::send_data $clientSocket error "serviceName is required"
          return
        }

        websocket_app::session_add $clientSocket fd $fd

        websocket_app::send_data $clientSocket "info" "log to $serviceName started"
      }

      logStop {

        websocket_app::try_session_close_fd $clientSocket fd
        websocket_app::send_data $clientSocket "info" "log stoped"
      }

      default {
        ${log}::debug "message not processed type: $msgType, data: $dataReceived"
      }

    }  
}

proc log_stream {clientSocket fd} {
  variable log

  ${log}::debug "log_stream"

  if {[eof $fd]} {
    websocket_app::send_data $clientSocket "stoped" "end of file"
    ::websocket::close $clientSocket
  } else {
    if {[gets $fd line] < 0} {
      puts "not to read"
    } else {
      websocket_app::send_data $clientSocket log $line
    }
  }
  # ::websocket::send $client_socket text "The server received '$data_received'!!	"
}

