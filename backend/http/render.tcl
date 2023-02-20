package require ornament
namespace import ornament::*

source "./json/json.tcl"


proc writeHttpHeaderStatus {chan {statusCode "200 OK"} } {
  
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

proc writeHttpHeaderContentType {chan {contentType "text/html"}} {
  puts $chan "Content-Type: $contentType"  
}

proc writeHttpHeader200 {chan body {contentType "text/html"}} {
  writeHttpHeaderStatus $chan
  writeHttpHeaderContentType $chan $contentType
  puts $chan ""
  puts $chan $body
}

proc writeHttpHeader {chan {statusCode "200 OK"} {contentType "text/html"}} {
  writeHttpHeaderStatus $chan $statusCode
  writeHttpHeaderContentType $chan $contentType
  puts $chan ""
}

proc render {template {vars ""} {cmds ""} } {
  set script [compile $template]
  return [run $script $cmds $vars]  
}

proc render404 {{errorTpl "error.html"}} {
  set vars [dict create statusCode "404" description "Not found" content ""]
  set cmds [dict create]
  return [render [readTemplateContent $errorTpl] $vars $cmds]
}

proc render500 {{errorTpl "error.html"} {error ""}} {
  set vars [dict create statusCode "500" description "Internal Server Error" content $error]
  set cmds [dict create]
  return [render [readTemplateContent $errorTpl] $vars $cmds]
}

proc readTemplateContent {filename} {

  global _configs

  set templatesPath [dict get $_configs "templates"]
  set errorTpl [open "$templatesPath/$filename" r]
  set errorTplContent [read $errorTpl]
  close $errorTpl
  return $errorTplContent
}

proc renderAsset {chan path} {
  set assetFile $path
  #puts "assetFile = $assetFile, exists = [file exists $assetFile]"

  if {[file exists $assetFile] == 0 } {
    writeHttpHeader $chan "404 Not found"
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
      writeHttpHeader200 $chan $assetContent $contentType
      close $assetFile      

    } err]} {
      writeHttpHeader $chan "500 Internal Server Error"
      puts $chan [render500 "error.html" $err]
    }
  }  
}

proc renderAsJson { chan data {statusCode 200}} {
  set contentType "application/json" 

  writeHttpHeaderStatus $chan $statusCode
  writeHttpHeaderContentType $chan $contentType

  puts $chan ""

  set payload [tcl2json $data]
  puts $chan [format "%s" $payload]
}

proc renderAsText { chan data {statusCode 200}} {
  set contentType "plain/text" 
  writeHttpHeader $chan $statusCode
  puts $chan [to_json $data]
}

proc renderAsHtml { chan data {statusCode 200}} {
  set contentType "text/html" 
  writeHttpHeader $chan $statusCode
  puts $chan [to_json $data]
}

proc renderBody {chan content} {
  set tpl ""
  set vars [dict create]
  set cmds [dict create]
  set text ""
  set html ""

  global _configs
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

  puts $chan "HTTP/1.0 200 OK"
  if { $text != "" } {
    writeHttpHeader200 $chan $text "text/plain" 
  } elseif { $html != "" } {
    writeHttpHeader200 $chan $html
    puts $chan $html
  } elseif { $tpl != "" } {
    writeHttpHeader200 $chan [render $tpl $vars $cmds]
  } else {
    writeHttpHeader $chan "500 Internal Server Error"
    puts $chan [render500 "error.html" "no render options found, use \[tpl | text | html | json]"]
  }
}