#!/bin/tclsh

package require json 1.3.3
package require json::write

proc tcl2json value {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    
    regexp {^value is a (.*?) with a refcount} \
  [::tcl::unsupported::representation $value] -> type

  if {[string match "pure*" $type]} {
      regexp {^value is a pure (.*?) with a refcount} \
    [::tcl::unsupported::representation $value] -> type
  }

  #puts " -> $value ==> [::tcl::unsupported::representation $value], type = $type"
 
    switch $type {
    string {
      #puts "write string $$value"
        return [json::write string $value]
    }
    dict {
        return [json::write object {*}[
      dict map {k v} $value {tcl2json $v}]]
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
      #puts "write string other $value"
        # Some other type; do some guessing...
        if {$value eq "null"} {
      # Tcl has *no* null value at all; empty strings are semantically
      # different and absent variables aren't values. So cheat!
      return $value
        } elseif {[string is integer -strict $value]} {
      return [expr {$value}]
        } elseif {[string is double -strict $value]} {
      return [expr {$value}]
        } elseif {[string is boolean -strict $value]} {
      return [expr {$value ? "true" : "false"}]
        }
        return [json::write string $value]
    }
  }
}

proc json2dict {text}  {
  return [json::json2dict $text]
}
