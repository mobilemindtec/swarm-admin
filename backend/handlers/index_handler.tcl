
package require logger 0.3

namespace eval index_handler {
  variable log
  set log [logger::init index_handler]
}

proc index_handler::index {request} {
	# default action
	return [dict create tpl "index.html"]
}

