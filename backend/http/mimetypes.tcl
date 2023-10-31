
source "./json/json.tcl"

set _mimes [dict create]
set _defaultMime ""

proc load_mimes {} {    
  set fd [open "./configs/mimetypes.json" r]
  set data [read $fd]
  set ::_mimes [json2dict $data]
  set ::_defaultMime [dict get $::_mimes default]
  close $fd 
}

proc get_mimetype {mime} {
  set count [dict size $::_mimes]

  if {$count == 0} {
    load_mimes
  }

  set mimes [dict get $::_mimes mimes]

  if {[dict exists $mimes $mime]} {
    dict get $mimes $mime
  } else {
    $::_defaultMime
  }
}