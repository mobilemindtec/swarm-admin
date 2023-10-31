
package require logger 0.3
package require coroutine
package require uuid

source "./http/http.tcl"
source "./core/router.tcl"
source "./core/websocket.tcl"
source "./configs/configs.tcl"
#source "./support/uuid.tcl"
source "./json/json.tcl"


namespace eval http_server {
  variable log
  set log [logger::init httpserver]
}

proc http_server::accept {socket addr port} {
  #set uuid [uuid::uuid generate]
  #chan configure $socket -blocking 0 -buffering line
  #set coro [coroutine ::$uuid {*}[list handle $socket $addr $port]]  

  chan configure $socket -blocking 0 -buffering line
  chan event $socket readable [list http_server::handle $socket $addr $port]  
}

proc http_server::handle {socket addr port} {
  variable log

  #fileevent $socket readable {}
  #fconfigure $socket -blocking 0

  if { [eof $socket]} {
    ${log}::debug "channel closed"
    try_close $socket
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
      set requestQuery [router::get_uri_query $requestURI]
      
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
    try_close $socket
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
  #puts "method=$requestMethod"
  if {[lsearch [list "GET" "OPTIONS"] $requestMethod] == -1} {
    set body [request::body_parse $requestBody $contentType]
  } else {
    set body [dict create]
  }

  if {$body == "not_supported"} {
    response::server_error $socket "content-type not supported" $contentType
    try_close $socket
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

  dispatch $socket $request

}

proc http_server::try_close {socket} {
  catch {close $socket}
}

proc http_server::dispatch {socket request} {

  variable log

  set path [dict get $request uri]
  set query [dict get $request query]
  set method [dict get $request method]
  set contentType [dict get $request contentType]
  set headers [dict get $request headers]

  ${log}::debug "HTTP REQUEST: $method $path"

  set body ""
  set handler ""

  if {[string match "/public/assets/*" $path]} {
    
    set assetsPath [dict get $app::configs "assets"]
    set map {} 
    lappend map "/public/assets" $assetsPath

    response::asset $socket [string map $map $path]    
    try_close $socket

  } elseif {[string match "/raw/logs/*" $path]} {
    
    set logsPath [dict get $app::configs docker logs path]
    set map {} 
    lappend map "/raw/logs" $logsPath

    response::raw $socket [string map $map $path]    
    try_close $socket

  } elseif {[string match "/download/logs/*" $path]} {
    
    set logsPath [dict get $app::configs docker logs path]
    set map {} 
    lappend map "/download/logs" $logsPath

    response::download $socket [string map $map $path]    
    try_close $socket

  } else {

    set foudedRoute [router::match $path $method]

    if { $foudedRoute == "not_found" } {
      ${log}::debug "route not found for $method $path"
      response::not_found $socket "Not Found" $contentType 
      try_close $socket   
      return
    }

    set routeName [dict get $foudedRoute route]
    set handler [dict get $foudedRoute handler]
    set pathVars [dict get $foudedRoute vars]
    set methods [dict get $foudedRoute methods]
    set auth [dict get $foudedRoute auth]
    set isWs [dict get $foudedRoute ws]
    set beforeHandlers [dict get $foudedRoute "before"]
    set afterHandlers [dict get $foudedRoute "after"]

    if { $handler == "" && !$isWs } {
      response::server_error $socket "handler not found" $contentType
      try_close $socket 
      return
    }

    if {[catch {

      dict set request route $routeName
      dict set request vars $pathVars

      foreach action $beforeHandlers {
        set ret [$action $request]  
        if {[dict exists $ret next]} {
          set request [dict get $ret next]
        } else {
          response::slect_render $socket $ret $contentType
          try_close $socket        
          return
        }
      }

      if {$isWs} {
        puts "do websocket upgrade"
        set headers [websocket_app::check_headers $headers]        
        websocket_app::upgrade $app::ServerSocket $socket $headers      
        return
      }
      
      ${log}::debug "handler = $handler"

      set response [$handler $request]

      foreach action $afterHandlers {
        set ret [$action $request $response]  
        if {[dict exists $ret next]} {
          set response [dict get $ret next]
        } else {
          response::slect_render $socket $ret $contentType
          try_close $socket
          return
        }
      }

      response::slect_render $socket $response $contentType
      try_close $socket

    } err]} {

      if {$err != ""} {
        ${log}::error "$::errorInfo"
        response::server_error $socket "error to process handler: $err" $contentType 
        try_close $socket
      }

    }        
  }
}






