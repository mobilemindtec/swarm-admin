 proc record { op rec args } {
   upvar type-$rec type
   upvar len-$rec len

   switch -exact $op {
    define {
             set type $args
             set len [ llength $args ]
           }
    new    {
             set varname [ lindex $args 0 ]
             set args [ lreplace $args 0 0 ]
             upvar $varname instance
             set instance [ eval list $rec $args ]
           }
    get    {
             upvar $rec instance
             set rec [ lindex $instance 0 ]
             upvar type-$rec type
             set element [ lsearch -exact $type $args ]
             if { $element == -1 } {
               bail "no such element $args in $rec"
             } else {
               incr element
               return [ lindex $instance $element ]
             }
           }
    set    { upvar $rec instance
             set instname $rec
             set rec [ lindex $instance 0 ]
             upvar type-$rec type
             set field [ lindex $args 0 ]
             if { [ llength $args ] == 1 } {
               return [ uplevel record get $instname $field ]
             }
             set value [ lrange $args 1 end ]
             set element [ lsearch -exact $type $field ]
             if { $element == -1 } {
               bail "no such element $field in $rec"
             } else {
               incr element
               return [set instance [lreplace $instance $element $element $value]]
             }
           }
  }
 }