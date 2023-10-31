#!/bin/tclsh



# ./configure ?--enable-threads? --with-tcl=/usr/lib/tcl8.6 --with-libcurl
#  sudo apt install libcurl4-openssl-dev
# sudo apt-get install tcl8.6-dev    

namespace eval http_client {

}

proc http_client::get {url {params ""} {query ""}} {
	call GET $url $query "" $params
}

proc http_client::post_json {url body {params ""} {query ""}} {
	lappend params json true
	post $url $body $params $query
} 

proc http_client::post {url body {params ""} {query ""}} {
	call POST $url $query $body $params
}

proc http_client::call {method url query body params} {


	set headers ""

	if {[dict exists $params "headers"]} {
		set pheaders [dict get $params "headers"]		
		foreach header $pheaders {
			lappend headers $header
		}
	}


	set isJson false
	set debug false
	set hasBody false

	if { $method == "POST" || $method == "PUT" } {
		set hasBody true		
	}


	if {[dict exists $params "json"] && [dict get $params "json"]} {
		set isJson true
	}

	if {[dict exists $params "debug"] && [dict get $params "debug"]} {
		set debug true
	}

	puts "params = $params, isJson  = $isJson"

	set payload ""

	if {$isJson} {
		lappend headers "Content-Type: application/json"

		if {$hasBody} {
			set payload [tcl2json $body]
		}

	} else {
	    lappend headers "Content-Type: application/x-www-form-urlencoded"
	    if {$hasBody} {
		    set pairs {}
		    foreach {name value} $body {
		        lappend pairs "[curl::escape $name]=[curl::escape $value]"
		    }
	    	set payload [join $pairs &]
	    }
	}

	if {$query != ""} {
	    set pairs {}
	    foreach {name value} $query {
	        lappend pairs "[curl::escape $name]=[curl::escape $value]"
	    }
	    append url ? [join $pairs &]		
	}


	if {$debug} {
		puts ""
		puts ""
		puts "........................................................."
		puts "$method $url"
		puts "HEADERS: $headers"
		puts "BODY: $payload"
	}



    set curlHandle [::curl::init]
    set response ""
    set responseBody ""

    switch $method { 
    	"POST" {
		    $curlHandle configure \
		    	-url $url \
		    	-post 1 \
		    	-postfields $payload \
		    	-httpheader $headers \
		    	-bodyvar responseBody 
	    }
	    "GET" {
		    $curlHandle configure \
		    	-url $url \
		    	-httpheader $headers \
		    	-bodyvar responseBody 	    	
	    }
	    default {
	    	puts "http method $method not implemented"
	    	exit 1
	    }
    }

    catch { 
    	set response [$curlHandle perform]
   	} curlErrorNumber

    if { $curlErrorNumber != 0 } {
        error [::curl::easystrerror $curlErrorNumber]
    }
    
    $curlHandle cleanup

    if {$debug} {
    	puts "ERROR NUMBER: $curlErrorNumber"
    	puts "RESPONSE: $response"
    	puts "RESPONSE BODY: $responseBody"
		puts "........................................................."
		puts ""
		puts ""
    }

    if {$isJson} {
    	if {[string match "\{*" $responseBody] || [string match "\[*" $responseBody]} {

    		if {$debug} {
    			puts "... parse response to json"
    		}

			return [json2dict $responseBody]    	
		}
    }

    return $responseBody
}



