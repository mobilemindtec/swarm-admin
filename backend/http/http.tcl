namespace import ornament::*

source "./json/json.tcl"
source "./http/mimetypes.tcl"


namespace eval response {

}

namespace eval request {
  
}

proc request::body_parse { body contentType } {

  switch $contentType {
    "application/json" {
      return [json2dict $body]
    }
    "text/plain" {
      return $body
    }
    "application/x-www-form-urlencoded" {
      set d [dict create]
      foreach pair [split $body "&"]  {
        set kv [split $pair "="]
        dict set d [lindex $kv 0] [lindex $kv 1]
      }
      return $d
    }
    default {
      return not_supported
    }
  }
}

proc response::body_format { body contentType {err false} } {

  if { $body == "" } {
    return ""
  }

  switch $contentType {
    "application/json" {
      return [tcl2json $body]
    }
    default {
      return $body
    }
  }
}

proc response::json_not_found {{body ""}} {
  return [dict create json $body statusCode 404]
}

proc response::json_unauthorized {{body ""}} {
  return [dict create json $body statusCode 401]
}

proc response::json_forbiden {{body ""}} {
  return [dict create json $body statusCode 403]
}

proc response::json_bad_request {{body ""}} {
  return [dict create json $body statusCode 400]
}

proc response::json_server_error {{body ""}} {
  return [dict create json $body statusCode 500]
}

proc response::json_error {msg} {
  return [dict create json [dict create error true message $msg] statusCode 500]
}

proc response::json_ok {{body ""}} {
  return [dict create json $body statusCode 200]
}

proc response::json_data_ok {{data ""} {lst false}} {
  if {$lst} {
    if {[llength $data] == 0} {
      set data {[]}
    }
  }
  set body [dict create messages {[]} error false data $data]
  return [dict create json $body statusCode 200]
}

proc response::json_created {{body ""} {location ""}} {

  set headers [dict create]

  if {$location ne ""} {
    set headers [dict create Location $location]
  }

  return [dict create json $body statusCode 201 headers $headers]
}

proc response::ok {socket body contentType } {
  puts $socket "HTTP/1.0 200"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""  
  puts $socket [body_format $body $contentType]
}

proc response::server_error { socket body contentType } {
  puts $socket "HTTP/1.0 500"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""  
  puts $socket [body_format $body $contentType true]
}

proc response::not_found { socket body contentType } {
  puts $socket "HTTP/1.0 404"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""    
  puts $socket [body_format $body $contentType true]
}

proc response::bad_request { socket body contentType } {
  puts $socket "HTTP/1.0 400"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""    
  puts $socket [body_format $body $contentType true]
}

proc response::write {chan body {statusCode 200} {contentType "text/plain"} {headers {}} } {
  
  switch $statusCode {
    200 {
      set status "200 OK"
    }
    400 {
      set status "400 Bad Request"
    }
    401 {
      set status "401 Unauthorized"
    }
    403 {
      set status "403 Forbidden"
    }
    500 {
      set status "500 Internal Server Error"
    }
    default {
      set status $statusCode
    }
  }  

  if {![dict exists $headers "content-type"] && ![dict exists $headers "Content-Type"]} {
    dict set headers "Content-Type" $contentType
  }

  puts $chan "HTTP/1.0 $status"

  foreach {k v} $headers {
    puts $chan "$k: $v"    
  }

  puts $chan ""
  puts $chan $body

}

proc response::render {template {vars ""} {cmds ""} } {
  set script [compile $template]
  return [run $script $cmds $vars]  
}

proc response::not_found_tpl {{errorTpl "error.html"}} {
  set vars [dict create statusCode "404" description "Not found" content ""]
  set cmds [dict create]
  return [render [template_content $errorTpl] $vars $cmds]
}

proc response::bad_request_tpl {{errorTpl "error.html"} {error ""}} {
  set vars [dict create statusCode "500" description "Internal Server Error" content $error]
  set cmds [dict create]
  return [render [template_content $errorTpl] $vars $cmds]
}

proc response::template_content {filename} {

  set templatesPath [dict get $app::configs "templates"]
  set errorTpl [open "$templatesPath/$filename" r]
  set errorTplContent [read $errorTpl]
  close $errorTpl
  return $errorTplContent
}

proc response::raw {chan filepath} {
  asset $chan $filepath
}

proc response::download {chan filepath} {
  asset $chan $filepath true
}

proc response::asset {chan path {download false}} {
  set assetFile $path
  #puts "assetFile = $assetFile, exists = [file exists $assetFile]"

  if {[file exists $assetFile] == 0 } {
    write $chan 404    
  } else {
    if {[catch {
      

      if {$download} {
        set contentType "application/octet-stream"
      } else {
        set splited [split $path .]
        set ext [lindex $splited end]
        set contentType [get_mimetype ".$ext"]       
      }

      set fsize [file size $assetFile]
      set assetFile [open $assetFile r]
      fconfigure $assetFile -translation binary
      set assetContent [read $assetFile]

      close $assetFile 
      
      set headers [dict create content-length $fsize] 

      chan configure $chan -translation binary
      write $chan $assetContent 200 $contentType $headers

    } err]} {
      write $chan "Internal Server Error" 500
    }
  }  
}

proc response::slect_render {socket response contentType} {

  variable log

  #${log}::debug "render_response $response"

  if {$response == ""} {
    ok $socket $response $contentType 
    return
  } 

  set bodyType "json"
  set statusCode 200
  set headers [dict create]
  set isList false

  if { [dict exists $response tpl] } {
    set bodyType tpl
  }

  if { [dict exists $response json] } {
    set bodyType json
  }

  if { [dict exists $response list] } {
    set isList true
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
      template $socket $response
    }
    json {
      set bodyValue [dict get $response json]

      
      if {$bodyValue eq ""} {

        switch $statusCode {
          200 {
            set bodyValue [dict create message "success"]
          }
          201 {
            set bodyValue [dict create message "Created"]
          }
          202 {
            set bodyValue [dict create message "Accepted"]
          }
          204 {
            set bodyValue [dict create message "No Content"]
          }
          400 {
            set bodyValue [dict create message "Bad Request"]
          }
          401 {
            set bodyValue [dict create message "Unauthorized"]
          }
          401 {
            set bodyValue [dict create message "Forbiden"]
          }
          404 {
            set bodyValue [dict create message "Not Found"]
          }
          500 {
            set bodyValue [dict create message "Server Error"]
          }
          default {
            set bodyValue [dict create message "Unknown error: $statusCode"] 
          }
        }

      }

      as_json $socket $bodyValue $statusCode $headers $isList
    }
    text {
      set bodyValue [dict get $response text]
      as_text $socket $bodyValue $statusCode $headers
    }
    html {
      set bodyValue [dict get $response html]
      as_html $socket $bodyValue $statusCode $headers
    }
    default {
      ${log}::error "unknow response type: $bodyType "
      write $socket $response 200 $contentType $headers
    }
  }        
}

proc response::as_json { chan data {statusCode 200} {headers {}} {isList false}} {
  set payload [tcl2json $data]
  write $chan $payload $statusCode "application/json" $headers
}

proc response::as_text { chan data {statusCode 200} {headers {}}} {
  write $chan $data $statusCode "plain/text" $headers
}

proc response::as_html { chan data {statusCode 200} {headers {}}} {
  write $chan $data $statusCode "text/html" $headers
}

proc response::template {chan content} {
  set tpl ""
  set vars [dict create]
  set cmds [dict create]
  set text ""
  set html ""
  set headers [dict create]

  set templatesPath [dict get $app::configs templates]

  if { [dict exists $content tpl] } {
    set tplFileName [dict get $content tpl]
    set tplFile [open "$templatesPath/$tplFileName"]
    set tpl [read $tplFile]
    close $tplFile
  }

  if { [dict exists $content vars] } {
    set vars [dict get $content vars]
  }

  if { [dict exists $content cmds] } {
    set cmds [dict get $content cmds]
  }

  if { [dict exists $content text] } {
    set text [dict get $content text]
  }

  if { [dict exists $content html] } {
    set html [dict get $content html]
  }

  if { [dict exists $content headers] } {
    set headers [dict get $content headers]
  }

  #puts $chan "HTTP/1.0 200 OK"
  if { $text != "" } {
    write $chan $text 200 "text/plain" 
  } elseif { $html != "" } {
    write $chan $html 200 "text/html" 
  } elseif { $tpl != "" } {
    set html [render $tpl $vars $cmds]
    write $chan $html 200 "text/html" 
  } else {
    write $chan "500 Internal Server Error" 500
  }
}