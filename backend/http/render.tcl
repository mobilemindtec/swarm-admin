package require ornament
namespace import ornament::*

source "./json/json.tcl"


proc body_parse { body contentType } {

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

proc body_format { body contentType {err false} } {

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

proc http_server_ok { socket body contentType } {
  puts $socket "HTTP/1.0 200"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""  
  puts $socket [body_format $body $contentType]
}

proc http_server_error { socket body contentType } {
  puts $socket "HTTP/1.0 500"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""  
  puts $socket [body_format $body $contentType true]
}

proc http_server_not_found { socket body contentType } {
  puts $socket "HTTP/1.0 404"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""    
  puts $socket [body_format $body $contentType true]
}

proc http_server_bad_request { socket body contentType } {
  puts $socket "HTTP/1.0 400"
  puts $socket "Content-Type: $contentType"  
  puts $socket ""    
  puts $socket [body_format $body $contentType true]
}

proc write_response {chan body {statusCode 200} {contentType "text/plain"} {headers {}} } {
  
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

proc render {template {vars ""} {cmds ""} } {
  set script [compile $template]
  return [run $script $cmds $vars]  
}

proc not_found_tpl {{errorTpl "error.html"}} {
  set vars [dict create statusCode "404" description "Not found" content ""]
  set cmds [dict create]
  return [render [render_template_content $errorTpl] $vars $cmds]
}

proc bad_request_tpl {{errorTpl "error.html"} {error ""}} {
  set vars [dict create statusCode "500" description "Internal Server Error" content $error]
  set cmds [dict create]
  return [render [render_template_content $errorTpl] $vars $cmds]
}

proc render_template_content {filename} {

  global _configs

  set templatesPath [dict get $_configs "templates"]
  set errorTpl [open "$templatesPath/$filename" r]
  set errorTplContent [read $errorTpl]
  close $errorTpl
  return $errorTplContent
}

proc render_asset {chan path} {
  set assetFile $path
  #puts "assetFile = $assetFile, exists = [file exists $assetFile]"

  if {[file exists $assetFile] == 0 } {
    write_response $chan 404    
  } else {
    if {[catch {
      
      set contentType "text/plain"
      
      if {[string match "*.css" $path]}  {
        set contentType "text/css"
      }

      if {[string match "*.js" $path]}  {
        set contentType "text/javascript"
      }

      if {[string match "*.png" $path]}  {
        set contentType "image/png"
      }

      if {[string match "*.gif" $path]}  {
        set contentType "image/gif"
      }

      if {[string match "*.jpeg" $path]}  {
        set contentType "image/jpeg"
      }

      set assetFile [open $assetFile r]
      set assetContent [read $assetFile]      
      close $assetFile      
      write_response $chan $assetContent 200 $contentType

    } err]} {
      write_response $chan "Internal Server Error" 500
    }
  }  
}

proc render_as_json { chan data {statusCode 200} {headers {}}} {
  set payload [tcl2json $data]
  write_response $chan $payload $statusCode "application/json" $headers
}

proc render_as_text { chan data {statusCode 200} {headers {}}} {
  write_response $chan $data $statusCode "plain/text" $headers
}

proc render_as_html { chan data {statusCode 200} {headers {}}} {
  write_response $chan $data $statusCode "text/html" $headers
}

proc render_template {chan content} {
  global _configs
  
  set tpl ""
  set vars [dict create]
  set cmds [dict create]
  set text ""
  set html ""
  set headers [dict create]

  set templatesPath [dict get $_configs templates]

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
    write_response $chan $text 200 "text/plain" 
  } elseif { $html != "" } {
    write_response $chan $html 200 "text/html" 
  } elseif { $tpl != "" } {
    set html [render $tpl $vars $cmds]
    write_response $chan $html 200 "text/html" 
  } else {
    write_response $chan "500 Internal Server Error" 500
  }
}