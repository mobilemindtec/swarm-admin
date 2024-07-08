#!/bin/tclsh

package require logger 0.3

source "./docker/docker-execute.tcl"
source "./docker/util.tcl"

namespace eval docker {
	variable log
	set log [logger::init docker-cmd]
}


proc docker::ps {} {
	variable log
	set cmd [list \
				docker \
				ps \
				--format \
				"{{.ID}},{{.Image}},{{.CreatedAt}},{{.State}},{{.Status}}"]

	proc pformat {line} {
		set rows [split $line ,] 	
		set data {}
		dict set data id [string trim [lindex $rows 0]]
		dict set data image [format_image [string trim [lindex $rows 1]]]
		dict set data createdAt [string trim [lindex $rows 2]]
		dict set data state [string trim [lindex $rows 3]]
		dict set data status [string trim [lindex $rows 4]]	
		return $data	
	}

	set results [execute_with_fmt $cmd pformat]

	return [dict create columns [list id name image createdAt state status] rows $results]
}

proc docker::stop {containerId} {
	variable log
	set cmd [list docker stop $containerId]
	execute $cmd
} 

# use credential helper
# https://github.com/awslabs/amazon-ecr-credential-helper
# sudo apt install amazon-ecr-credential-helper
# vim ~/.docker/config.json
#{
#	"credsStore": "ecr-login",
#	"auths": {
#		"<id>.dkr.ecr.us-east-1.amazonaws.com": {
#			"auth": ""
#		}
#	}
#}

proc docker::aws_login {} {
	variable log

	set region [get_cnf docker aws region]
	set ecrId [get_cnf docker aws ecr_id]

	set cmdLogin [list  aws \
									ecr get-login-password \
									--region $region | docker login \
									--username AWS \
									--password-stdin $ecrId.dkr.ecr.$region.amazonaws.com]
	set cmdEval [list "eval \$(aws ecr get-login-password --region $region)"]
	
	set result [execute $cmdLogin]

	if {[dict get $result error]} {
		return $result
	}

	execute $cmdEval
} 




