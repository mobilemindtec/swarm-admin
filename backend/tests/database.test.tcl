#!/bin/tclsh

package require tcltest
namespace import ::tcltest::*

source "./configs/configs.tcl"
source "./database/db.tcl"

namespace eval app {
  variable configs
  
  set configs [load_configs]
} 


test database-select-by-wildcard-test {
	mysql select wildcard fail
} -body {
	
    set r [db::select "select 1 from mysql.user where user = ? and user = ?" [list test test]]
    if {[$r has_error]} {
      puts "get error info [$r get_error_info]"
    } else {
      puts "resuls [$r get_data]"
    }
    return [$r has_error]

} -result 0

test database-select-by-colon-test {
  mysql select colon fail
} -body {
  
    set r [db::select "select 1 from mysql.user where user = :xxx and user = :yy" {xxx test yy test}]
    if {[$r has_error]} {
      puts "get error info [$r get_error_info]"
    } else {
      puts "resuls [$r get_data]"
    }
    return [$r has_error]

} -result 0

test database-select-by-colon-test {
  mysql select 
} -body {
  
    set r [db::select "select 1 from mysql.user"]
    if {[$r has_error]} {
      puts "get error info [$r get_error_info]"
    } else {
      puts "resuls [$r get_data]"
    }
    return [$r has_error]

} -result 0


test database-ddl-batch {
  mysql ddl batch
} -body {
  
  set createTable {
    drop table if exists test; 
    create table test (
      id int primary key not null auto_increment,
      name varchar(100) not null
    );
  }

    set r [db::execute_batch $createTable]
    if {[$r has_error]} {
      puts "get error info [$r get_error_info]"
    } else {
      puts "resuls [$r get_data]"
    }
    return [$r has_error]

} -result 0


test database-ddl {
  mysql ddl
} -body {
  
  set dropTable {drop table if exists test}  

  set r [db::execute $dropTable]
  if {[$r has_error]} {
    puts "get error info [$r get_error_info]"
  } else {
    puts "resuls [$r get_data]"
  }
  return [$r has_error]

} -result 0

test insert-data {
  mysql insert data
} -body {
  
  set ddl {
    drop table if exists employees;
    drop table if exists employers;
    create table employers (
      id int primary key not null auto_increment,
      name varchar(100) not null
    );
    create table employees (
      id int primary key not null auto_increment,
      name varchar(100) not null,
      employer_id int not null,
      foreign key (employer_id) references employers(id)       
    );
  }  

  set r [db::execute_batch $ddl]
  if {[$r has_error]} {
    puts "get error info [$r get_error_info]"
  } else {
    
    set sql {
      insert into employers (name) values (?);
      insert into employers (name) values (?);
      insert into employers (name) values (?);
    } 

    set params {
      "Mobile Mind"
      "Hos Sistemas"
      "Metadados"
    }


    set r [db::execute_batch $sql $params]

    if {[$r has_error]} {
      puts "get error info [$r get_error_info]"      
    } else {
      set r [db::select {select id, name from employers}]

      if {[$r has_error]} {
        puts "get error info [$r get_error_info]"
      } else {

        set data [$r get_data]

        puts "data = $data"

        foreach row $data {
          puts "row = $row"       
        }
      }
    }
  }
  return [$r has_error]

} -result 0


test database-trans {
  mysql trans
} -body {
  
  set dropTable {drop table if exists test}  

  set r [db::execute $dropTable]
  if {[$r has_error]} {
    puts "get error info [$r get_error_info]"
  } else {
    puts "resuls [$r get_data]"
  }
  return [$r has_error]

} -result 0