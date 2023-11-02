package require mysqltcl
package require logger 0.3
package require TclOO

source "./configs/configs.tcl"
source "./database/result_set.tcl"

namespace eval db {
  variable log
  variable showSql
  set log [logger::init db]
  set showSql false
}

namespace eval pool {
  variable MysqlPool
  variable log
  set MysqlPool [list]
  set log [logger::init pool]
}

proc pool::show_pool_size {} {
  variable MysqlPool
  set size [llength $MysqlPool]
  puts "pool size $size"
}

proc pool::init {{count 1}} {
  init_pool $count
}

proc pool::init_pool {{count 1}} {
  variable MysqlPool
  variable log

  set id [llength $MysqlPool]

  for {set i 0} {$i < $count} {incr i} {
    incr $id
    set conn [db::mysql_connect false]

    if {[$conn has_error]} {
      ${log}::error "db pool init error: [$conn get_error_info]"
    }

    $conn set_id $id
    lappend MysqlPool [dict create conn $conn busy false]
  }

  #show_pool_size
}

proc pool::acquire {} {
  variable MysqlPool

  set len [llength $MysqlPool]

  for {set i 0} {$i < $len} {incr i} {

    set item [lindex $MysqlPool $i]
    set conn [dict get $item conn]

    if {![dict get $item busy]} {
      dict set item busy true
      lset MysqlPool $i $item
      return $conn
    }
  }

  init_pool 10

  return [acquire]

  # try new alloc
}

proc pool::release {currConn} {
  variable MysqlPool


  transaction_done $currConn

  set id [$currConn get_id]
  set len [llength $MysqlPool]

  for {set i 0} {$i < $len} {incr i} {
    set item [lindex $MysqlPool $i]
    set conn [dict get $item conn]

    if {[$conn get_id] == $id} {
      dict set item busy false      
      lset MysqlPool $i $item
      break
    }
  }

  #show_pool_size
}  

proc pool::transaction_done {rconn} {
  variable log 
  set handle [$rconn get_dbhandle]

  if {![$rconn is_autocommit]} {
    if {[$rconn has_error]} {
      if {[catch {::mysql::rollback $handle} err]} {
        if {$err != ""} {
          ${log}::error "error mysql rollback: $err"
        }
      }
    } else {
      if {[catch {::mysql::commit $handle} err]} {
        if {$err != ""} {
          ${log}::error "error mysql commit: $err"
        }
      }      
    }
  }
}




proc db::sanitaze {value} {
  #set regex1 {\D}
  #set regex2 {[^[:alpha:]]}
  #set regex {[^[:alnum:][:space:]]}
  #regsub -all $regex $value ""
  
  set value [regsub -all {'} $value {\'}]
  set value [regsub -all {"} $value {\"}]
  set value [regsub -all {;} $value {\;}]
  set value [regsub -all {\-} $value {\-}]

  return $value
}

proc db::get_query {sql params} {
 set sql {}
  set sp [split $query ?]

  if {[llength $args] == [llength $sp]} {
    $result set_error "params count not match"
    return $result
  }

  set c [llength $args]

  for {set i 0} {$i < $c} {incr i} {
    set v [sanitaze [lindex $args]]
    set part [lindex $sp]
    set sql "$sql $part '$v'"
  }  
}

proc db::get_database_params {} {
  variable showSql
  set env dev 

  if {[info exists ::env(ENV)]} {
    switch $::env(ENV) {
      dev {
        set env dev
        set showSql true
      }
      test {
        set env test
        set showSql true
      }
      prod {
        set env prod
      }
    }
  }

  set user [get_cnf database $env mysql user]
  set password [get_cnf database $env mysql password]
  set database [get_cnf database $env mysql database]
  set host [get_cnf database $env mysql host]
  set port [get_cnf database $env mysql port]

  if {[info exists ::env(MYSQL_USER)]} {
    set user $::env(MYSQL_USER)
  } 

  if {[info exists ::env(MYSQL_PASSWORD)]} {
    set password $::env(MYSQL_PASSWORD)
  } 

  if {[info exists ::env(MYSQL_DATABASE)]} {
    set database $::env(MYSQL_DATABASE)
  } 

  if {[info exists ::env(MYSQL_HOST)]} {
    set host $::env(MYSQL_HOST)
  } 

  if {[info exists ::env(MYSQL_PORT)]} {
    set port $::env(MYSQL_PORT)
  }

  dict create user $user password $password database $database host $host port $port   
}

proc db::mysql_connect {{autocommit true}} {
  
  set dbhandle {}
  set result [ResultSet new]
  set params [get_database_params]
  set user [dict get $params user]
  set password [dict get $params password]
  set database [dict get $params database]
  set host [dict get $params host]
  set port [dict get $params port]

  #if {[info exists _dbhandle]} {
  #  return  $_dbhandle
  #}

  if {[catch {set dbhandle [mysqlconnect -host $host \
                                          -port $port \
                                          -user $user \
                                          -password $password \
                                          -db $database]} err]} {    
    $result set_error $err                                     

  } else {
    ::mysql::autocommit $dbhandle $autocommit
    ::mysql::use $dbhandle $database
    $result set_dbhandle $dbhandle
    $result set_autocommit $autocommit
  }

  return $result
} 

proc db::mysql_close {rconn} {
  variable log 
  set handle [$rconn get_dbhandle]

  if {![$rconn is_autocommit]} {
    if {[$rconn has_error]} {
      if {catch {::mysql::rollback $handle} err} {
        if {$err != ""} {
          ${log}::error "error mysql rollback: $err"
        }
      }
    } else {
      if {catch {::mysql::commit $handle} err} {
        if {$err != ""} {
          ${log}::error "error mysql commit: $err"
        }
      }      
    }
  }

  if {catch {::mysql::close $handle} err} {
    if {$err != ""} {
      ${log}::error "error mysql close: $err"
    }
  }        
}


proc db::replace_any_query_params {query params} {

  set chars [split $query  ""]
  set len [llength $chars]
  set sql {}
  set pindex 0
  set skipAtIdx -1

  for {set i 0} {$i < $len} {incr i} {

    if {$skipAtIdx > 0 && $i <= $skipAtIdx} { continue }
    
    set char [lindex $chars $i]

    if {"$char" == "?"} {

      if {$pindex >= [llength $params]} {
        return -code error "indexed param $pindex not found on params"
      }

      set param [lindex $params $pindex]
      set param [sanitaze $param]

      switch "$param" {
        "true" {
          set sql $sql'1'
        }
        "false" {
          set sql $sql'0'
        }
        default {
          set sql $sql'$param'
        }
      }

      incr pindex

    } elseif {"$char" == ":"} {
      
      set restOfQuery [string range $query $i+1 end]
      set nextArg [split $restOfQuery " "]
      set argKey [lindex $nextArg 0]
      set skipAtIdx [expr $i + [string length $argKey]]

      if {![dict exists $params $argKey]} {
        return -code error "key $argKey not found on params dict"
      }

      set param [dict get $params $argKey]
      set param [sanitaze $param]

      switch "$param" {
        "true" {
          set sql $sql'1'
        }
        "false" {
          set sql $sql'0'
        }
        default {
          set sql $sql'$param'
        }
      }

    } else {
      set sql $sql$char
    }
  }

  return $sql
}

proc db::replace_query_params_by_wildcard {query params} {
  set parts [split $query ?]
  set pn [expr {[llength $parts] - 1}]
  set an [llength $params]
  set sql {}

  if {$pn != $an} {
    $result set_error "args count not match? $pn != $an"
    return $result
  }
    
  for {set i 0} {$i < $pn} {incr i} {
    set part [lindex $parts $i]
    set arg [lindex $params $i]
    set arg [sanitaze $arg]
    set sql "$sql $part '$arg'" 
  }  

  return $sql
}

proc db::replace_query_params_by_colon {query params} {
  set parts [split $query :]
  set n [llength $parts]
  set pn [expr {$n - 1}]
  set plist {}
  set sql {}

  # [select .. where x =, :x]
  # first :x on index 1
  for {set i 1} {$i < $n} {incr i} {
    set p [lindex $parts $i]  
    set idx [string first " " $p]
    if {$idx > -1} {
      set param [string range $p 0 $idx]
      set rest [string range $p $idx end-1]
      lset parts $i $rest  
    } else {
      # last :? on last position
      set param $p
    }
    lappend plist [string trim $param]
  }

  for {set i 0} {$i < $pn} {incr i} {
    set part [lindex $parts $i]
    set argkey [lindex $plist $i]
    set arg [dict get $params $argkey] 
    set arg [sanitaze $arg]
    set sql "$sql $part '$arg'" 
  }   

  return $sql
}

proc db::compile_query {query params} {
  switch -regexp -- $query {
    {\?} {
      return [replace_any_query_params $query $params]
    }
    {:} {
      return [replace_any_query_params $query $params]
    }   
    default {
      return $query
    } 
  }
}

proc db::raw {sql {trans {}}} {
  variable showSql
  set isTrans [expr { $trans != ""}]

  if {$isTrans} {
    set rconn $trans
  } else {
    set rconn [pool::acquire]
  }

  set result [ResultSet new]

  if {[$rconn has_error]} {
    pool::release $rconn
    return $rconn
  }

  set handle [$rconn get_dbhandle]

  if {$showSql} {
    puts "SQL: $sql"
  }

  if {[catch {
    set data [::mysql::exec $handle $sql]
    $result set_data $data
  } err]} {
    $result set_error $err
  }

  if {!$isTrans} {
    pool::release $rconn
  }

  return $result
}

proc db::raw_select_one {sql {trans {}}} {

  set rs [raw_select $sql $trans]

  if {[$rs has_error]} {
    return $rs
  }

  set data [$rs get_data]

  if {[llength $data] == 0} {
    return $rs
  }

  $rs set_data [lindex $data 0]

  return $rs
}

proc db::raw_select {sql {trans {}}} {
  variable showSql
  set isTrans [expr {$trans != ""}]

  if {$isTrans} {
    set rconn $trans
  } else {
    set rconn [pool::acquire]
  }  

  set result [ResultSet new]

  if {[$rconn has_error]} {
    pool::release $rconn
    return $rconn
  }

  if {$showSql} {
    puts "SQL: $sql"
  }

  set handle [$rconn get_dbhandle]

  if {[catch {
    set data [::mysql::sel $handle $sql -list]
    $result set_data $data
  } err]} {
    $result set_error $err
  }

  if {!$isTrans} {
    pool::release $rconn
  }

  return $result
}

proc db::select {query {params {}} {trans {}}} {
  set sql [compile_query $query $params]
  return [raw_select $sql $trans]
}

proc db::select_one {query {params {}} {trans {}}} {
  set sql [compile_query $query $params]
  return [raw_select_one $sql $trans]
}

proc db::execute {query {params {}} {trans {}}} {
  set sql [compile_query $query $params]
  return [raw $sql $trans]
}

proc db::execute_batch {query {params {}} {trans {}}} {
  variable showSql
  set isTrans [expr {$trans != ""}]

  if {$isTrans} {
    set rconn $conn
  } else {
    #set rconn [mysql_connect]
    set rconn [pool::acquire]
  }

  set result [ResultSet new]

  if {[$rconn has_error]} {
    pool::release $rconn
    return $rconn
  }

  set handle [$rconn get_dbhandle]
  set cmds [list $query]

  if {[string match {*;*} $query]} {
    set vals [split $query \;]
    set cmds {}
    foreach s $vals {
      if {[string trim $s] != ""} {
        lappend cmds $s
      }
    }
  }
  
  set hasArgs [expr [llength $params] > 0]

  if {$hasArgs && [llength $params] != [llength $cmds]} {
    return -code error {params not match}
  }

  set idx 0

  foreach cmd $cmds {  
    if {[catch {
      
      set arg {}
      
      if {$hasArgs} {
        set arg [lindex $params $idx]
        incr idx
      }

      set cmd [compile_query $cmd $params]

      if {$showSql} {
        puts "SQL: $cmd"
      }

      set data [::mysql::exec $handle $cmd]

      $result set_data $data
    } err]} {
      $result set_error $err
      break
    }
  }

  if {!$isTrans} {
    #mysql_close $rconn
    pool::release $rconn
  }

  return $result
}

proc db::tx {lambda args} {

  variable showSql

  if {$showSql} {
    puts "TX: open"
  }

  set conn [pool::acquire]

  if {[$conn has_error]} {
    pool::release $conn
    return $conn
  }

  set result ""


  try {
    set params [list $conn {*}$args]
    set result [apply $lambda {*}$params]      
  } on error err {
    puts "error apply tx: $err"
    error $err  
  }
  
  if {$showSql} {
    puts "TX: close"
  }

  pool::release $conn
  
  return $result
}

proc db::insert {table entity {trans {}}} {

  set fields ""
  set stmts ""
  set values {}

  dict for {k v} $entity {
    set fields "${fields}${k}, "
    set stmts "${stmts}?, "
    lappend values $v
  }

  set fields [string range $fields 0 end-2]
  set stmts [string range $stmts 0 end-2]

  set sqlInsert "insert into $table ( $fields ) values ( $stmts );"
  set sqlLastId "SELECT LAST_INSERT_ID();"

  set err ""

  if {$trans == ""} {
    set rs [tx { {t values sqlInsert sqlLastId} {
      set rs [db::execute $sqlInsert $values $t]
      if {[$rs has_error]} {
        return $rs
      } 
      return [db::raw_select_one $sqlLastId $t]

    }} $values $sqlInsert $sqlLastId]
  } else {
      set rs [execute $sqlInsert $values $t]    
      if {[$rs has_error]} {
        return $rs
      } 
      set rs [raw_select_one $sqlLastId]    
  }

  if {[$rs has_error]} {
    return $rs
  } 

  dict set entity id [lindex [$rs get_data] 0]

  $rs set_data $entity

  return $rs
}

proc db::update {table entity {trans {}}} {

  set fields ""
  set values {}
  set id ""

  dict for {k v} $entity {
    if {$k == "id"} {
      set id $v       
    } else {
      set fields "${fields}${k} = ?, "
      lappend values $v
    }
  }

  lappend values $id

  set fields [string range $fields 0 end-2]

  set sql "update $table set $fields where id = ?"

  set rs [execute $sql $values $trans]
  
  return $rs
}

proc db::count {table id {trans {}}} {
  set sql "select count(*) from $table where id = ?"
  set r [select_one $sql $id $trans]
}

proc db::delete {table id {trans {}}} {
  set sql "delete from $table where id = ?"
  return [execute $sql $id $trans]
}

proc db::first {table cols id {trans {}}} {
  set fields [join $cols ", "]
  set sql "select $fields from $table where id = ? limit 1"
  return [select_one $sql $id $trans]
}

proc db::all {table cols {trans {}}} {
  set fields [join $cols ", "]
  set sql "select $fields from $table"
  return [select $sql "" $trans]
}

proc db::where {table cols cond params {trans {}}} {
  set fields [join $cols ", "]
  set sql "select $fields from $table where $cond"
  return [select $sql $params $trans]
}

proc db::where_first {table cols cond params {trans {}}} {
  set fields [join $cols ", "]
  set sql "select $fields from $table where $cond limit 1"
  return [select_one $sql $params $trans]
}