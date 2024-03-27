
package require http
package require tls

http::register https 443 [list ::tls::socket -autoservername true]

namespace eval authenticator_service {
	variable log
	set log [logger::init authenticator_service]
}

proc authenticator_service::authenticate {code} {
	set secret [get_cnf authenticator secret]
	set url [get_cnf authenticator url]
	set url "$url/Validate.aspx?Pin=$code&SecretCode=$secret"

	set token [http::geturl $url]
	set data [::http::data $token]
	::http::cleanup $token
	return [expr {$data == "True"}]
}

proc authenticator_service::pair {} {
	set secret [get_cnf authenticator secret]
	set url [get_cnf authenticator url]
	set url "$url/pair.aspx?AppName=SwarmAdmin&AppInfo=MobileMind&SecretCode=$secret"

	set token [http::geturl $url]
	set data [::http::data $token]
	::http::cleanup $token
	return $data
	
}


