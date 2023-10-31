

package require logger
package require coroutine
package require uuid

source "./database/db.tcl"
#source "./support/uuid.tcl"
source "./workers/person_worker.tcl"

namespace eval person_service {

	variable log
	variable cache

	set cache [dict create]
	set log [logger::init person_service] 

}

proc person_service::is_valid_date {date {date_format "%Y-%m-%d"}} {
	set unix [clock scan $date -format $date_format]
	set formatted [clock format $unix -format $date_format]
  return [string equal $formatted $date]
}

proc person_service::validate {data} {

	set nickname [dict get $data apelido]
	set name [dict get $data nome]
	set birthday [dict get $data nascimento]
	set stack [dict get $data stack]

	foreach it [list $name $nickname $birthday] {
		if {$it == "" || $it == "null"} {
			return validation_empty
		}
	}

	if {[string length $nickname] > 32 } {
		return validation_size			
	}

	if {[string length $name] > 100 } {
		return validation_size			
	}

	foreach it $stack {
		if {[string length $it] > 32 } {
			return validation_size			
		}
	}

	foreach it [list $name $nickname] {
		if {[string is integer -strict $it]} {
			return validation_type			
		}
	}

	foreach it $stack {

		if {$it == "null"} {
			return validation_empty
		}

		if {[string is integer -strict $it]} {
			return validation_type			
		}
	}


	if {![regexp {[[:digit:]]{4,4}-[[:digit:]]{2,2}-[[:digit:]]{2,2}} $birthday]} {
		return validation_type
	}

	set parts [split $birthday -]

	if {[expr {[lindex $parts 0] < 1900}]} {
		return validation_type	
	}

	set y [lindex $parts 0]
	set m [lindex $parts 1]
	set d [lindex $parts 2]

	if {$m > 12 || $m < 1} {
		return validation_type	
	}

	if {$d > 31 || $d < 1} {
		return validation_type	
	}

	if {$d > 28 && $m == 2} {
		return validation_type		
	}

	#if {[catch {
	#	if {![is_valid_date $birthday]} {
	#		return validation_empty
	#	}
	#} err]} {
	#	if {$err != ""} {				
	#		return validation_empty
	#	}
	#}

	return ok
}

proc person_service::prepare {data} {

	set stack [dict get $data stack]

	if {[llength $stack] > 0} {
		set stack [join $stack ,]
	}

	set id [uuid::uuid generate]

	dict set data id $id
	dict set data stack $stack

	#after 10 [list person_service::do_insert $data]

	#person_worker::dispatch $data



	return $data
}


proc person_service::create {data} {

	variable cache

	set data [prepare $data]
	set id [dict get $data id]

	set nickname [dict get $data apelido]
	set name [dict get $data nome]
	set birthday [dict get $data nascimento]
	set stack [dict get $data stack]
	set search "$nickname,$name,$birthday,$stack"

	#person_db_worker::send $data

	dict set cache $id $data
	dict set cache $search $data
	dict set cache $nickname $data

	return $id
}

proc person_service::exists_by_nickname {nickname} {

	variable cache

	if {[dict exists $cache $nickname]} {
		return {exists true}
	}

	set result [db::select "select count(*) from people where nickname = ?" [list $nickname]]

	if {[$result has_error]} {
		return [dict create error [$result get_error_info]]
	} 

	set data [$result get_data]


	if {[llength $data] > 0} {

		set count [lindex [lindex $data 0] 0]

		dict set cache $nickname true

		return [list exists [expr {$count > 0}]]
	}		

	return {exists false}		
}

proc person_service::find_by_id {id} {

	variable cache

	if {[dict exists $cache $id]} {
		return [dict get $cache $id]
	}

	set result [db::select "select id, nickname, name, birthday, stack from people where id = ?" [list $id]]

	if {[$result has_error]} {
		return [dict create error [$result get_error_info]]
	} 
	
	set data [$result get_data]
	set entity {}

	if {[llength $data] > 0} {

		set data [lindex $data 0]

		dict set entity id [lindex $data 0]
		dict set entity apelido [lindex $data 1]
		dict set entity nome [lindex $data 2]
		dict set entity nascimento [lindex $data 3]
		dict set entity stack [split [lindex $data 4] ,]

		dict set cache $id $entity
	}
	
	return $entity
}

proc person_service::search {query} {
	
	variable cache
	variable log


	dict for {k v} $cache {
		if {[string match $query $k]} {
			return [dict create json $v]
		}
	} 


	set result [db::select "select id, nickname, name, birthday, stack from people where search like ? limit 10" [list "%${query}%"]]

	if {[$result has_error]} {		
		return [dict create error [$result get_error_info]]	
	}

	set data [$result get_data]
	set entities [list]

	foreach it $data {

		set result [dict create]
		dict set result id [lindex $it 0]
		dict set result apelido [lindex $it 1]
		dict set result nome [lindex $it 2]
		dict set result nascimento [lindex $it 3]
		dict set result stack [split [lindex $it 4] ,]

		lappend entities $result
	}	

	return $entities
}

proc person_service::count {} {
	set result [db::select "select count(*) from people"]
	set response [dict create]

	if {[$result has_error]} {
		return [dict create error [$result get_error_info]]	
	}
	
	set data [$result get_data]
	return [dict create count [lindex [lindex $data 0] 0]]
}	

proc person_service::do_insert {data} {

	variable log

	#puts "do_insert = $data"

	set sql {
		insert into people 
			(id, nickname, name, birthday, stack, search) 
			values (?, ?, ?, ?, ?, ?)
	}


	set id [dict get $data id]
	set nickname [dict get $data apelido]
	set name [dict get $data nome]
	set birthday [dict get $data nascimento]
	set stack [dict get $data stack]
	set search "$nickname,$name,$birthday,$stack" 
	set params [list $id $nickname $name $birthday $stack $search]
	set result [db::execute $sql $params]
	
	if {[$result has_error]} {
		${log}::error "insert error: [$result get_error_info]"
		puts "id = $id, nickname = $nickname, name = $name, birthday = $birthday, stack = $stack"
	} 

}	


