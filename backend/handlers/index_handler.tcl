
package require logger 0.3

set log [logger::init main]


proc index {request} {
	# default action
	return [dict create tpl "index.html"]
}

