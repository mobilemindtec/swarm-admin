package require logger 0.3


package require sha256
package require base64

source "./support/uuid.tcl"
source "./configs/configs.tcl"
source "./json/json.tcl"


namespace eval jwt {
	variable log

	set log [logger::init jwt]
}

proc jwt::token {} {
	
	variable log

	set exp [expr [clock seconds] + 3600]
	set header [string map {\n "" "=" ""} [::base64::encode "{\"alg\":\"RS256\",\"typ\":\"JWT\"}"]]
	set claims [string map {\n "" "=" ""} [::base64::encode "{\
	\"iss\":\"[uuid::new]\",\
	\"exp\": $exp,\
	\"iat\":[clock seconds]\
	}"]]

	set signature "$header.$claims"

	set secret [get_cnf jwt secret]

	set sig [string map {\n "" "=" ""} [::base64::encode [::sha2::hmac $secret $signature]]]
	set final "$signature.$sig"

	#token_validate $final

	return [dict create token $final expires_at $exp]
}

proc jwt::validate {token} {

	variable log

	set parts [split $token .]
	set header [lindex $parts 0]
	set claims [lindex $parts 1]
	set sig [lindex $parts 2]

	set signature "$header.$claims"

	set secret [get_cnf jwt secret]

	set newSig [string map {\n "" "=" ""} [::base64::encode [::sha2::hmac $secret $signature]]]
	

	if {$newSig != $sig} {
		${log}::debug "invalid token"
		return false
	}

	set decoded [::base64::decode $claims]	
	set data [json2dict $decoded]
	set exp [dict get $data exp]

	if {$exp < [clock seconds]} {
		${log}::debug "expired token"
		return false
	}


	${log}::debug "valid token!"

	return true

}
