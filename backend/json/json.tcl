#!/bin/tclsh

package require json 1.3.3
package require json::write


# json data.
# if has json template, dict has been key data with json data and key tpl with tpl info.
# tpl is a dict with field name and type. if tpl type not found to field, so try auto discover type.
proc tcl2json {value {tplType ""}} {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    
    regexp {^value is a (.*?) with a refcount} \
  [::tcl::unsupported::representation $value] -> type

  if {[string match "pure*" $type]} {
      regexp {^value is a pure (.*?) with a refcount} \
    [::tcl::unsupported::representation $value] -> type
  }

  #puts " -> $value ==> [::tcl::unsupported::representation $value], type = $type"

  if {$tplType ne ""} {
    switch $tplType {
      string {
        if {$value eq "null"} {
          return $value
        } else {
          return [json::write string $value]
        }
      }
      int - double {
        return [expr {$value}]
      }
      boolean {
        if {[string is true -strict $value]} {
          return true
        } else {
          return false
        }        
      }
      list {
        return [json::write array $value]       
      }
    }
  }
 
  switch $type {
    dict {

      if {[dict exists $value tpl] && [dict exists $value data]} {

        set data [dict get $value data]
        set tpl [dict get $value tpl]      
        set mapResult {}

        dict for {k v} $data {
          set type ""

          if {[dict exists $tpl $k]} {
            set type [dict get $tpl $k] 
          } 

          dict set mapResult $k [tcl2json $v $type]
        }

      } else {
        set mapResult [dict map {k v} $value {tcl2json $v}]
      }

      return [json::write object {*}$mapResult]
    }
    list {
      return [json::write array {*}[lmap v $value {tcl2json $v}]]
    }
    int - double {
      return [expr {$value}]
    }
    booleanString {
      return [expr {$value ? "true" : "false"}]
    }
    default {
      if {$value eq "null"} {
      # Tcl has *no* null value at all; empty strings are semantically
      # different and absent variables aren't values. So cheat!
        return $value
      } elseif {$value eq {[]}} {
        return [json::write array [list]]
      } elseif {[string is integer -strict $value]} {
        return [expr {$value}]
      } elseif {[string is double -strict $value]} {
        return [expr {$value}]
      } elseif {[string is boolean -strict $value]} {
        return [expr {$value ? true : false}]
      } elseif {[string is true -strict $value]} {
        return true
      } elseif {[string is false -strict $value]} {
        return false
      }
      return [json::write string $value]
    }
  }
}

proc json2dict {text}  {
  return [json::json2dict $text]
}
