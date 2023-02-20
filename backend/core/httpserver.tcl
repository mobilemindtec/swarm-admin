package require logger 0.3

set log [logger::init main]


source "./http/render.tcl"
source "./core/router.tcl"

global _routes
global _configs

set _configs [dict create]
set _routes [dict create]

dict set _configs templates "./public/templates"
dict set _configs assets "./public/assets"




proc httpServe {chan addr port} {
  fconfigure $chan -translation auto -buffering line

  variable log

  set line [gets $chan]
  #puts "line = $line"
  #set path [file join . [string trimleft [lindex $line 1] /]]
  set path "/[string trim [lindex $line 1] /]"

  set parts [split $path "?"]
  
  set path [lindex $parts 0]
  set queries [lindex $parts 1]

  ${log}::info "HTTP REQUEST: $path, QUERY = $queries"

  global _routes
  global _configs

  set body ""
  set handler ""

  set query {}

  foreach var [split $queries ";"] {
    if { [string trim $var] == "" } {
      continue
    }
    set param [split $var "="]
    set k [lindex $param 0] 
    set v [lindex $param 1]
    dict set query $k $v 
  }

  set assetsPath [dict get $_configs "assets"]

  if {[string match "/public/assets/*" $path]}  {
    
    set map {} 
    lappend map "/public/assets" $assetsPath

    renderAsset $chan [string map $map $path]    

  } else {

    set foudedRoute [findRoute $_routes $path]

    if { $foudedRoute == "not_found" } {
      writeHttpHeader $chan "404 Not found"      
      puts $chan [render404]      
      return
    }

    set routeName [dict get $foudedRoute route]
    set handler [dict get $foudedRoute handler]
    set pathVars [dict get $foudedRoute vars]


    if { $handler != "" } {

      if {[catch {

        ${log}::debug "execute handler $handler"

        set request {}
        dict set request path $path
        dict set request route $routeName
        dict set request query $query
        dict set request vars $pathVars


        #puts "execute handler"
        set body [$handler $request]


        if { $body == "" } {
          writeHttpHeader $chan "404 Not found"      
          puts $chan [render404]
        } 


        set bodyType "json"
        set statusCode 200

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
            renderBody $chan $body
          }
          json {                
            set bodyValue [dict get $body json]
            renderAsJson $chan $bodyValue $statusCode
          }
          text {
            set bodyValue [dict get $body json]
            renderAsText $chan $bodyValue $statusCode
          }
          html {
            set bodyValue [dict get $body json]
            renderAsHtml $chan $bodyValue $statusCode
          }
          default {
            ${log}::error "unknow body type: $bodyType "
            writeHttpHeader $chan "500 Internal Server Error"
            puts $chan [render500 "error.html" "unknow body type: $bodyType "]                            
          }
        }        


      } err]} {

        ${log}::error "Error to process handler to route $routeName: $err"

        writeHttpHeader $chan "500 Internal Server Error"
        puts $chan [render500 "error.html" $err]

      }      

    } else {
      
      ${log}::error "HTTP HANDLER not found to route $routeName, $handler"    
      writeHttpHeader $chan "404 Not found"      
      puts $chan [render404]
    } 
  }

  close $chan
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

proc runApp {configs routes} {
  puts "http server init..."
  global _routes
  global _configs

  if { [isDict $routes] && [dict size $routes] > 0 } {
    set _routes $routes
  }

  if { [isDict $configs] && [dict size $configs] > 0 } {
    set _configs $configs
  }
  set sk [socket -server httpServe 5151]  
  vwait forever
}

