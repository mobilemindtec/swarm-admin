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

proc wr_http_status {chan {statusCode "200 OK"} } {
  
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

  puts $chan "HTTP/1.0 $status"
}

proc wr_http_ctype {chan {contentType "text/html"}} {
  puts $chan "Content-Type: $contentType"  
}

proc wr_http_ok {chan body {contentType "text/html"}} {
  wr_http_status $chan
  wr_http_ctype $chan $contentType
  puts $chan ""
  puts $chan $body
}

proc wr_http_header {chan {statusCode "200 OK"} {contentType "text/html"}} {
  wr_http_status $chan $statusCode
  wr_http_ctype $chan $contentType
  puts $chan ""
}

proc render {template {vars ""} {cmds ""} } {
  set script [compile $template]
  return [run $script $cmds $vars]  
}

proc not_found {{errorTpl "error.html"}} {
  set vars [dict create statusCode "404" description "Not found" content ""]
  set cmds [dict create]
  return [render [render_template_content $errorTpl] $vars $cmds]
}

proc bad_request {{errorTpl "error.html"} {error ""}} {
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
    wr_http_header $chan "404 Not found"
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
      wr_http_ok $chan $assetContent $contentType
      close $assetFile      

    } err]} {
      wr_http_header $chan "500 Internal Server Error"
      puts $chan [bad_request "error.html" $err]
    }
  }  
}

proc render_as_json { chan data {statusCode 200}} {
  set contentType "application/json" 

  wr_http_status $chan $statusCode
  wr_http_ctype $chan $contentType

  puts $chan ""

  set payload [tcl2json $data]

  puts $chan $payload
}

proc render_as_text { chan data {statusCode 200}} {
  set contentType "plain/text" 
  wr_http_header $chan $statusCode
  puts $chan [to_json $data]
}

proc render_as_html { chan data {statusCode 200}} {
  set contentType "text/html" 
  wr_http_header $chan $statusCode
  puts $chan [to_json $data]
}

proc render_template {chan content} {
  global _configs
  
  set tpl ""
  set vars [dict create]
  set cmds [dict create]
  set text ""
  set html ""

  set templatesPath [dict get $_configs "templates"]

  if { [dict exists $content "tpl"] } {
    set tplFileName [dict get $content "tpl"]
    set tplFile [open "$templatesPath/$tplFileName"]
    set tpl [read $tplFile]
    close $tplFile
  }

  if { [dict exists $content "vars"] } {
    set vars [dict get $content "vars"]
  }

  if { [dict exists $content "cmds"] } {
    set cmds [dict get $content "cmds"]
  }

  if { [dict exists $content "text"] } {
    set text [dict get $content "text"]
  }

  if { [dict exists $content "html"] } {
    set html [dict get $content "html"]
  }

  #puts $chan "HTTP/1.0 200 OK"
  if { $text != "" } {
    wr_http_ok $chan $text "text/plain" 
  } elseif { $html != "" } {
    wr_http_ok $chan $html
    #puts $chan $html
  } elseif { $tpl != "" } {
    wr_http_ok $chan [render $tpl $vars $cmds]
  } else {
    wr_http_header $chan "500 Internal Server Error"
    puts $chan [bad_request "error.html" "no render options found, use \[tpl | text | html | json]"]
  }
}