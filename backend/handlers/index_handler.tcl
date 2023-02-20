

source "./core/docker.tcl"
source "./http/render.tcl"

set tableDockerLs {
!* commandSubst true variableSubst true backslashSubst true
  <table style="width: 100%; min-width: 100%">
     <thead>
        <tr>
!         foreach col $columns {
            <th>$col</th>
!         }
        </tr>
     </thead>
     <tbody>
!       foreach row $rows {
        <tr>
!         foreach col $columns {
!!          set rowVal [dict get $row $col]
!           if { $col == "name" } {
            <td>
              <a href="/docker/service/ps/$rowVal">$rowVal</a>
            </td>
!           } else {
              <td>$rowVal</td>
!           }
!         } 
        </tr>
!       }
     </tbody>
  </table>
! if {[llength $rows] eq -0} {
    <span>no services</span>
! }  
}

set tableDockerPs  {
!* commandSubst true variableSubst true backslashSubst true
  <table style="width: 100%; min-width: 100%">
     <thead>
        <tr>
!         foreach col $columns {
            <th>$col</th>
!         }
					<th>logs</th>
        </tr>
     </thead>
     <tbody>
!       foreach row $rows {
        <tr>
!         foreach col $columns {
!!          set rowVal [dict get $row $col]
!!          set name [dict get $row "name"]
              <td>$rowVal</td>
!         } 
					<td>
						<a href="/docker/service/logs/$name">open</a>
					</td>
        </tr>
!       }
     </tbody>
  </table>
! if {[llength $rows] eq -0} {
    <span>no service</span>
! }  
}

proc DockerServiceList {request} {

	set cmd "ls"
	set query [dict get $request query]
	set results [execDockerCmd  "service ls"]
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	if { [dict exists $query media] } {
		if { [dict get $query media] == "json" } {
			return [dict create json [dict create rows $rows colmuns $columns]]
		}
	}

	# You can pass variables to the template
	set vars [dict create columns $columns rows $rows cmd $cmd]

	# int is the safe interpreter that is running the script
	proc getContent {cmd columns rows int} {	 
	  global tableDockerLs
		return [render $tableDockerLs	[dict create columns $columns rows $rows]]			
	}

	# You can pass commands to the template
	set cmds [dict create getContent [list getContent $cmd $columns $rows]]
	return [dict create tpl "index.html" vars $vars cmds $cmds]
}

proc DockerServicePs {request} {

	set cmd "ps"
	set pathVars [dict get $request vars]
	set serviceId [dict get $pathVars id]
	set results [execDockerCmd  "service ps" $serviceId]	
	set columns [dict get $results columns]
	set rows [dict get $results rows]

	# You can pass variables to the template
	set vars [dict create columns $columns rows $rows cmd $cmd]

	# int is the safe interpreter that is running the script
	proc getContent {cmd columns rows int} {	  
	  global tableDockerPs
		return [render $tableDockerPs [dict create columns $columns rows $rows]]		
	}
	# You can pass commands to the template
	set cmds [dict create getContent [list getContent $cmd $columns $rows]]
	return [dict create tpl "index.html" vars $vars cmds $cmds]
}

proc DockerNodeLs {request} {
	return [DockerServiceList $request]
}

proc DockerNodePs {request} {
	return [DockerServicePs $request]
}

proc DockerPs {request} {
	
}

proc IndexGet {request} {
	# default action
	return [DockerServiceList $request]
}

