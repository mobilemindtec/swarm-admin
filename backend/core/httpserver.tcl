
package require logger 0.3
package require coroutine

set log [logger::init main]

source "./http/render.tcl"
source "./core/router.tcl"
source "./configs/configs.tcl"
source "./support/uuid.tcl"
source "./json/json.tcl"

global _routes
global _configs



proc http_serve {socket addr port} {
  #fconfigure $chan -translation crlf -buffering line
  #chan configure $chan -translation {crlf crlf} -blocking 0 -buffering full -buffersize 4096
  #chan event $chan readable [list get_reply $chan]

  fconfigure $socket -blocking 0
  fileevent $socket readable [list server_receive $socket]

  #set uuid [new_uuid]
  #set coro [coroutine $uuid {*}[list get_reply $uuid $chan]]
  #chan event $chan readable $coro
}

proc server_receive {socket} {
  variable log

  if { [eof $socket]} {
    ${log}::debug "channel closed"
    close $socket
    return
  }

  # Default request data, they are overwritten if explicitly specified in 
  # the HTTP request
  set RequestMethod ""
  set RequestURI ""
  set RequestProtocol ""
  set RequestHeader [dict create connection "close" accept "text/plain" accept-encoding "" content-type "text/plain"]
  set RequestBody ""
  set RequestQuery {}
  set RequestAcceptGZip 0; # Indicates that the request accepts a gzipped response

  set state connecting

  while {[gets $socket line]>=0} {
    #${log}::debug $line
    # Decode the HTTP request line
    if {$state=="connecting"} {
      if {![regexp {^(\w+)\s+(/.*)\s+(HTTP/[\d\.]+)} $line {} RequestMethod RequestURI RequestProtocol]} {
        break }

      #set path "/[string trim [lindex $line 1] /]"
      set parts [split $RequestURI ?]
      set RequestURI [lindex $parts 0]

      set queries [lindex $parts 1]

      foreach var [split $queries "&"] {
        if { [string trim $var] == "" } {
          continue
        }
        set param [split $var "="]
        set k [lindex $param 0] 
        set v [lindex $param 1]
        dict set RequestQuery $k $v 
      }

      set state header

    # Read the header/RequestData lines
    } elseif {$state=="header"} {
      if {$line!=""} {
        if {[regexp {^\s*([^: ]+)\s*:\s*(.*)\s*$} $line {} AttrName AttrValue]} {
          dict set RequestHeader [string tolower $AttrName] $AttrValue
        } else {
          # RequestData not recognized, ignore it
          ${log}::debug {Unable to interpret RequestData: $line}
        }
      } else {
        set state body
        break; # Header is completed, read now the body
      }
    }
  }

  if {$state=="connecting"} {
    ${log}::debug {  No data received -> close socket}
    catch {close $socket}
    return
  }  

  if {$state=="body"} {
    fconfigure $socket -translation {binary crlf}


    set RequestBody {}
    
    # Read the body in binary mode to match the content length and avoid
    # any unwanted translation of binary data
    fconfigure $socket -translation {binary crlf}

    set TransferEncoding ""
    if {[dict exists $RequestHeader transfer-encoding]} {
      set TransferEncoding [dict get $RequestHeader transfer-encoding]
    }

    # RFC7230 - 3.3.3. Message Body Length
    # If a Transfer-Encoding header field is present and the chunked
    # transfer coding (Section 4.1) is the final encoding, the message
    # body length is determined by reading and decoding the chunked
    # data until the transfer coding indicates the data is complete.
    if {[string match {*chunked} $TransferEncoding]} {
      while {![eof $socket]} {
        set ChunkHeader ""
        while {$ChunkHeader==""} {
          gets $socket ChunkHeader
        }

        # The chunk header can include "chunk extensions" after a semicolon
        set ChunkSizeHex [lindex [split $ChunkHeader {;}] 0]
        set ChunkSize [expr 0x$ChunkSizeHex]
        if {$ChunkSize==0} {
          break}

        set CurrentChunk {}
        while {![eof $socket]} {
          if {[string bytelength $CurrentChunk]>=$ChunkSize} {
            break}
          append CurrentChunk [read $socket $ChunkSize]
        }

        append RequestBody $CurrentChunk
      }

      #dict set Response ErrorStatus 501
      #dict set Response ErrorBody {Chunked transfer encoding not supported}
      #Log {Chunked transfer encoding not supported} info 2
    } elseif {[dict exists $RequestHeader content-length]} {
      # Read the number of bytes defined by the content-length header
      set ContentLength [dict get $RequestHeader content-length]
      while {![eof $socket]} {
        if {[string bytelength $RequestBody]>=$ContentLength} {
          break}
        append RequestBody [read $socket $ContentLength]
      }
    
    } else {
      # No "content-length" and not "transfer-encoding" doesn't end
      # in "chunked". So there should be no body.
    }

    # Switch back to the standard translation mode
    fconfigure $socket -translation {auto crlf}

    #if {$RequestBody!=""} {
    #  ${log}::debug {Received body length: [string bytelength $RequestBody]}
    #  ${log}::debug "RequestBody = $RequestBody"
    #}
     
  }



  set contentType [dict get $RequestHeader "content-type"]

  if {[lsearch [list "GET" "OPTIONS"] $RequestMethod] == -1} {
    set body [body_parse $RequestBody $contentType]
  } else {
    set body [dict create]
  }

  if { $body == "not_supported" } {
    http_server_error $socket "content-type not supported" $contentType
    close $socket
    return
  }

  #set RequestURITail [string range $RequestURI [lindex $ResponderDef 2] end]
  set request [dict create]  
  dict set request method $RequestMethod 
  dict set request uri $RequestURI 
  dict set request headers $RequestHeader 
  dict set request body $body 
  dict set request rowBody $RequestBody
  dict set request query $RequestQuery
  dict set request contentType $contentType

  #${log}::debug "request = $request"

  dispatch $socket $request

}

proc dispatch {socket request} {

  global _routes
  global _configs

  variable log

  set path [dict get $request uri]
  set query [dict get $request query]
  set method [dict get $request method]
  set contentType [dict get $request contentType]

  ${log}::debug "HTTP REQUEST: $path"

  set body ""
  set handler ""

  set assetsPath [dict get $_configs "assets"]

  if {[string match "/public/assets/*" $path]}  {
    
    set map {} 
    lappend map "/public/assets" $assetsPath

    render_asset $socket [string map $map $path]    
    close $socket

  } else {

    set foudedRoute [find_route $_routes $path]

    if { $foudedRoute == "not_found" } {      
      http_server_not_found $socket "Not Found" $contentType 
      close $socket   
      return
    }

    set routeName [dict get $foudedRoute route]
    set handler [dict get $foudedRoute handler]
    set pathVars [dict get $foudedRoute vars]
    set methods [dict get $foudedRoute methods]
    set auth [dict get $foudedRoute auth]
    set beforeHandlers [dict get $foudedRoute "before"]
    set afterHandlers [dict get $foudedRoute "after"]

    if {[lsearch $methods [string tolower $method]] == -1} {      
      http_server_not_found $socket "Not Found" $contentType 
      close $socket   
      return      
    }

    if { $handler == "" } {
      ${log}::error "HTTP HANDLER not found to route $routeName, $handler"    
      http_server_error $socket "Server Error" $contentType
      close $socket 
      return
    }

    if {[catch {

      ${log}::debug "execute handler $handler"

      dict set request route $routeName
      dict set request vars $pathVars

      foreach action $beforeHandlers {
        set ret [$action $request]  
        if {[dict exists $ret next]} {
          set request [dict get $ret next]
        } else {
          render_response $socket $ret $contentType
          return
        }
      }

      #puts "execute handler"
      set response [$handler $request]

      foreach action $afterHandlers {
        set ret [$action $request $response]  
        if {[dict exists $ret next]} {
          set response [dict get $ret next]
        } else {
          render_response $socket $ret $contentType
          return
        }
      }

      render_response $socket $response $contentType
      
    } err]} {

      if {$err != ""} {
        ${log}::error "Error to process handler to route $routeName: $err"

        http_server_error $socket "Server Error" $contentType 
        close $socket
      }

      #wr_http_header $socket "500 Internal Server Error"
      #puts $socket [bad_request "error.html" $err]
    }        
  }
}


proc render_response {socket body contentType} {

  variable log

  ${log}::debug "render_response $body"

  set bodyType "json"
  set statusCode 200

  if { $body == "" } {
    http_server_ok $socket $body $contentType 
    close $socket
    return
  } 

  if { [dict exists $body tpl] } {
    set bodyType tpl
  }

  if { [dict exists $body json] } {
    set bodyType json
  }

  if { [dict exists $body text] } {
    set bodyType text
  }

  if { [dict exists $body statusCode] } {
    set statusCode [dict get $body statusCode]
  }

  set bodyValue ""

  switch $bodyType {
    tpl {
      render_template $socket $body
    }
    json {                
      set bodyValue [dict get $body json]
      render_as_json $socket $bodyValue $statusCode
    }
    text {
      set bodyValue [dict get $body json]
      render_as_text $socket $bodyValue $statusCode
    }
    html {
      set bodyValue [dict get $body json]
      render_as_html $socket $bodyValue $statusCode
    }
    default {
      ${log}::error "unknow body type: $bodyType "
      #wr_http_header $socket "500 Internal Server Error"
      #puts $socket [bad_request "error.html" "unknow body type: $bodyType "]                            
      http_server_ok $socket $body $contentType 
    }
  }    

  close $socket    
}

  #if { [catch {
  #  set fl [open $path]
  #} err] } {
  #  puts $chan "HTTP/1.0 404 Not Found"
  #} else {
  #  puts $chan "HTTP/1.0 200 OK"
  #  puts $chan "Content-Type: text/html"
  #  puts $chan ""
  #  puts $chan [GetIndex]; # [read $fl]
  #  close $fl
  #}
  #close $chan


proc isDict {d} {
  expr {[string is list $d]
      && !([llength $d] % 2)
      && ((2 * [llength [dict keys $d]]) == [llength $d])
  }
}

proc run_app {configs routes} {
  global _routes
  global _configs

  if { [isDict $routes] && [dict size $routes] > 0 } {
    set _routes $routes
  } 

  if { [isDict $configs] && [dict size $configs] > 0 } {
    set _configs $configs
  } 

  set port [get_config $_configs 5151 server port]

  puts "http server init on port $port..."
  set sk [socket -server http_serve [expr $port * 1]]  

  vwait forever
}

