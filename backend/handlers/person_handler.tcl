
package require logger 0.3
package require uuid

source "services/person_service.tcl"

set log [logger::init index_handler]


proc person_create {request} {


	set data [dict get $request body]

	#puts "data = $data"

	set validation [person_service::validate $data]
	
	switch $validation {
		
		validation_empty {

			return {text "empty" statusCode 422}
		}
		
		validation_size {
			return {text "size" statusCode 422}
		}
		
		validation_type {
			return {text "type" statusCode 400}	
		}
		
		default {

			#set exists [person_service::exists_by_nickname [dict get $data apelido]]
			#if {[dict exists $exists error]} {
			#	return [list text [dict get $exists error] statusCode 500]
			#}
			#if {[dict get $exists exists]} {
			#	return {text "exists" statusCode 422}
			#}
			
			set id [person_service::create $data] 
			return [dict create text "" statusCode 201 headers [dict create Location "/pessoas/$id"]]
		}

	}
}

proc person_find {request} {


	set id [dict get $request vars id]

	set result [person_service::find_by_id $id]

	if {$result == ""} {
		return {text "" statusCode 404}	
	}

	if {[dict exists $result error]} {
		return [list text [dict get $result error] statusCode 500]	
	}

	return [dict create json $result]
}

proc person_search {request} {
	
	if {![dict exists $request query] || ![dict exists $request query t] } {
		return {text "" statusCode 422}
	}

	set query [dict get $request query t]
	set result [person_service::search $query]

	if {[dict exists $result error]} {
		return [list text [dict get $result error] statusCode 500]	
	}

	if {[catch {
		set r [dict create json $result]
	} err]} {
		if {$err != ""} {
			puts "search error: $err -> $result"
		}
	}

	return $r

}

proc person_count {request} {
	set result [person_service::count]

	if {[dict exists $result error]} {
		return [list text [dict get $result error] statusCode 500]	
	}

	return [list text [dict get $result count]]		
}


