
package require logger 0.3

set log [logger::init index_handler]


proc index {request} {
	# default action
	return [dict create tpl "index.html"]
}

