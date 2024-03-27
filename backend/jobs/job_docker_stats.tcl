
namespace eval job_docker_stats {
	variable log
	set log [logger::init job_docker_stats]
}


proc job_docker_stats::collect_proc_stats {} {

	set cmd [list \
				docker stats \
				--no-stream \
				--no-trunc]
	set results [split [exec {*}$cmd] \n]
	set results [lrange $results 1 end]
	
	foreach it $results {		
		lassign $it id name cpu mem
		set name [lindex [split $name .] 0]
		puts "$name - $cpu $mem"    	
	}

	# CONTAINER ID                                                       NAME                                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O        BLOCK I/O        PIDS
	# aed834f14cd25f0086cafb28e80a466d4904bbbda416b5c7bf91ec529fbbabdf   gym_gateway.1.hwr27vee9lbojuxmu4iyc8fri    0.00%     47.73MiB / 21.44GiB   0.22%     212kB / 0B     66.1MB / 0B      37
	# c8eab9bcdd0a1ffc573549b04b97b9bbadf9515c1e828626a59ee7258f42058f   gym_rabbitmq.1.m82n9c2m70rbxz7j1nacyyh57   0.17%     163.9MiB / 21.44GiB   0.75%     211kB / 874B   55.9MB / 115kB   38
	# 9cb74317e2f550f9d73d1081294e483dce3e4d695f0ad2de32cabceff45a30af   gym_customer.1.y6id3qn9q7tmhp0e2g0sa63vh   0.22%     9.945MiB / 21.44GiB   0.05%     970B / 638B    0B / 0B          11


}

proc job_docker_stats::collect_df_stats {} {

	set cmd [list \
				docker system df]
	set results [split [exec {*}$cmd] \n]
	set results [lrange $results 1 end]

	foreach it $results {		
		lassign $it type total active size reclaimable
		
		puts "$type - $reclaimable"    	
	}

	# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
	# Images          37        20        19.19GB   18GB (93%)
	# Containers      68        3         8.367GB   8.367GB (100%)
	# Local Volumes   1         1         74.76kB   0B (0%)
	# Build Cache     25        0         1.827GB   1.827GB

}

proc job_docker_stats::schedule {} {
	after 0 job_docker_stats::job1
	after 0 job_docker_stats::job2
}

proc job_docker_stats::job1 {} {

	variable log

	try {
		job_docker_stats::collect_proc_stats
	} on error err {
		${log}::debug "error run job collect_proc_stats: $err"
	}

	after 10000 job_docker_stats::job1
}

proc job_docker_stats::job2 {} {

	variable log

	try {
		job_docker_stats::collect_df_stats
	} on error err {
		${log}::debug "error run job collect_df_stats: $err"
	}

	after 10000 job_docker_stats::job2
}