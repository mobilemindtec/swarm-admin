
package require logger 0.3
package require coroutine

set log [logger::init httpserver]

source "./http/render.tcl"
source "./core/router.tcl"
source "./configs/configs.tcl"
source "./support/uuid.tcl"
source "./json/json.tcl"

global _routes
global _configs

proc get_uri_query {uri} {
  set parts [split $uri ?]
  set queries [lindex $parts 1]
  set requestQuery [dict create]

  foreach var [split $queries "&"] {
    if { [string trim $var] == "" } {
      continue
    }
    set param [split $var "="]
    set k [lindex $param 0] 
    set v [lindex $param 1]
    dict set requestQuery $k $v 
  }  
  return $requestQuery
}

proc http_serve {socket addr port} {

  # case 1
  #fconfigure $socket -translation crlf -buffering line
  #socket configure $socket -translation {crlf crlf} -blocking 0 -buffering full -buffersize 4096
  #socket event $socket readable [list get_reply $socket]

  # case 2
  #fconfigure $socket -blocking 0
  #fileevent $socket readable [list server_receive $socket]

  # case 3
  
  set uuid [new_uuid]
  set coro [coroutine ::$uuid {*}[list server_receive $socket $uuid]]
  
  #fconfigure $socket -blocking 0
  #socket event $socket readable $coro  
}

proc server_receive {socket uuid} {
  variable log

  fileevent $socket readable {}
  fconfigure $socket -blocking 0

  if { [eof $socket]} {
    ${log}::debug "channel closed"
    close $socket
    return
  }

  # Default request data, they are overwritten if explicitly specified in 
  # the HTTP request
  set requestMethod ""
  set requestURI ""
  set requestProtocol ""
  set requestHeader [dict create connection "close" accept "text/plain" accept-encoding "" content-type "text/plain"]
  set requestBody {}
  set requestQuery {}
  #set RequestAcceptGZip 0; # Indicates that the request accepts a gzipped response
  set state connecting

  # while {[gets $socket line]>=0}

  while {1} {

    set readCount [::coroutine::util::gets_safety $socket 4096 line]

    #if { $readCount <= 0} {
    #  break
    #}

    #${log}::debug $line
    # Decode the HTTP request line
    if {$state=="connecting"} {
      if {![regexp {^(\w+)\s+(/.*)\s+(HTTP/[\d\.]+)} $line {} requestMethod requestURI requestProtocol]} {
        break }

      #set path "/[string trim [lindex $line 1] /]"
      set requestQuery [get_uri_query $requestURI]
      
      # remove query from URI
      set parts [split $requestURI ?]
      set requestURI [lindex $parts 0]

      set state header

    # Read the header/RequestData lines
    } elseif {$state=="header"} {
      if {$line!=""} {
        if {[regexp {^\s*([^: ]+)\s*:\s*(.*)\s*$} $line {} AttrName AttrValue]} {
          dict set requestHeader [string tolower $AttrName] $AttrValue
        } else {
          # RequestData not recognized, ignore it
          ${log}::error {Unable to interpret RequestData: $line}
        }
      } else {
        set state body
        # Header is completed, read now the body
        break
      }
    }
  }

  if {$state=="connecting"} {
    ${log}::debug {  No data received -> close socket}
    catch {close $socket}
    return
  }  

  if {$state=="body"} {

    #fconfigure $socket -translation {binary crlf}

    
    # Read the body in binary mode to match the content length and avoid
    # any unwanted translation of binary data
    fconfigure $socket -translation {binary crlf}

    set transferEncoding ""
    if {[dict exists $requestHeader transfer-encoding]} {
      set transferEncoding [dict get $requestHeader transfer-encoding]
    }

    # RFC7230 - 3.3.3. Message Body Length
    # If a Transfer-Encoding header field is present and the chunked
    # transfer coding (Section 4.1) is the final encoding, the message
    # body length is determined by reading and decoding the chunked
    # data until the transfer coding indicates the data is complete.
    if {[string match {*chunked} $transferEncoding]} {
      while {![eof $socket]} {
        set chunkHeader ""
        while {$chunkHeader==""} {
          gets $socket chunkHeader
        }

        # The chunk header can include "chunk extensions" after a semicolon
        set chunkSizeHex [lindex [split $chunkHeader {;}] 0]
        set chunkSize [expr 0x$chunkSizeHex]
        if {$chunkSize==0} {
          break}

        set currentChunk {}
        while {![eof $socket]} {
          if {[string bytelength $currentChunk]>=$chunkSize} {
            break}
          append currentChunk [read $socket $chunkSize]
        }

        append requestBody $currentChunk
      }

      #dict set Response ErrorStatus 501
      #dict set Response ErrorBody {Chunked transfer encoding not supported}
      #Log {Chunked transfer encoding not supported} info 2
    } elseif {[dict exists $requestHeader content-length]} {
      # Read the number of bytes defined by the content-length header
      set contentLength [dict get $requestHeader content-length]
      while {![eof $socket]} {
        if {[string bytelength $requestBody]>=$contentLength} {
          break}
        append requestBody [read $socket $contentLength]
      }
    
    } else {
      # No "content-length" and not "transfer-encoding" doesn't end
      # in "chunked". So there should be no body.
    }

    # Switch back to the standard translation mode
    fconfigure $socket -translation {auto crlf}

    #if {$requestBody!=""} {
    #  ${log}::debug {Received body length: [string bytelength $requestBody]}
    #  ${log}::debug "requestBody = $requestBody"
    #}
     
  }

  set contentType [dict get $requestHeader "content-type"]

  #puts "requestBody = $requestBody"

  if {[lsearch [list "GET" "OPTIONS"] $requestMethod] == -1} {
    set body [body_parse $requestBody $contentType]
  } else {
    set body [dict create]
  }

  if {$body == "not_supported"} {
    http_server_error $socket "content-type not supported" $contentType
    close $socket
    return
  }

  #set requestURITail [string range $requestURI [lindex $ResponderDef 2] end]
  set request [dict create]  
  dict set request method $requestMethod 
  dict set request uri $requestURI 
  dict set request headers $requestHeader 
  dict set request body $body 
  dict set request rowBody $requestBody
  dict set request query $requestQuery
  dict set request contentType $contentType

  #${log}::debug "request = $request"

  dispatch_handler $socket $request

}

proc dispatch_handler {socket request} {

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

  if {[string match "/public/assets/*" $path]}  {
    
    set assetsPath [dict get $_configs "assets"]
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
      ${log}::error "HTTP HANDLER not found to route $routeName"    
      http_server_error $socket "Internal Server Error" $contentType
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
          close $socket
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
          close $socket
          return
        }
      }

      render_response $socket $response $contentType
      close $socket

    } err]} {

      if {$err != ""} {
        ${log}::error "Error to process handler to route $routeName: $err"

        http_server_error $socket "Internal Server Error" $contentType 
        close $socket
      }

    }        
  }
}


proc render_response {socket response contentType} {

  variable log

  #${log}::debug "render_response $response"

  if {$response == ""} {
    http_server_ok $socket $response $contentType 
    return
  } 

  set bodyType "json"
  set statusCode 200
  set headers [dict create]

  if { [dict exists $response tpl] } {
    set bodyType tpl
  }

  if { [dict exists $response json] } {
    set bodyType json
  }

  if { [dict exists $response text] } {
    set bodyType text
  }

  if { [dict exists $response statusCode] } {
    set statusCode [dict get $response statusCode]
  }

  if { [dict exists $response headers] } {
    set headers [dict get $response headers]
  }

  set bodyValue ""

  switch $bodyType {
    tpl {
      render_template $socket $response
    }
    json {                
      set bodyValue [dict get $response json]
      render_as_json $socket $bodyValue $statusCode $headers
    }
    text {
      set bodyValue [dict get $response json]
      render_as_text $socket $bodyValue $statusCode $headers
    }
    html {
      set bodyValue [dict get $response json]
      render_as_html $socket $bodyValue $statusCode $headers
    }
    default {
      ${log}::error "unknow response type: $bodyType "
      write_response $socket $response 200 $contentType $headers
    }
  }        
}

proc run_app {configs routes} {
  global _routes
  global _configs

  set _routes $routes
  set _configs $configs

  set port [get_config $_configs 5151 server port]

  puts "http server started on http://localhost:$port"
  set sk [socket -server http_serve [expr $port * 1]]  
  vwait forever
}

