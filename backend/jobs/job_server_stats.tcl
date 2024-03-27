
namespace eval job_server_stats {
	variable log
	set log [logger::init job_server_stats]
}


proc job_server_stats::collect_proc_stats {} {

	set cmd [list ps -aux]
	set results [split [exec {*}$cmd] \n]
	set results [lrange $results 1 end]
	
	foreach it $results {		
		lassign $it _user _pid cpu mem _vsz _rss _tty _stat _start _time command		
		puts "$command - $cpu $mem"    	
	}	

	# USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
	#root           1  1.3  0.0  22360 13044 ?        Ss   22:03   0:30 /sbin/init
	#root           2  0.0  0.0      0     0 ?        S    22:03   0:00 [kthreadd]
	#root           3  0.0  0.0      0     0 ?        S    22:03   0:00 [pool_workqueue_release]
	#root           4  0.0  0.0      0     0 ?        I<   22:03   0:00 [kworker/R-rcu_g]
	#root           5  0.0  0.0      0     0 ?        I<   22:03   0:00 [kworker/R-rcu_p]


}

proc job_server_stats::collect_disk_stats {} {

	set cmd [list df -BG]
	set results [split [exec {*}$cmd] \n]
	set results [lrange $results 1 end]
	
	foreach it $results {		
		lassign $it fs size used available in_use mounted		
		puts "$mounted - $used ($in_use) of $available"    	
	}	

	#Filesystem     1G-blocks  Used Available Use% Mounted on
	#dev                  11G    0G       11G   0% /dev
	#run                  11G    1G       11G   1% /run
	#efivarfs              1G    1G        1G  97% /sys/firmware/efi/efivars
	#/dev/nvme0n1p3      274G   95G      166G  37% /
	#tmpfs                11G    1G       11G   1% /dev/shm
	#tmpfs                11G    1G       11G   1% /tmp
	#/dev/nvme0n1p4      180G  119G       52G  70% /mnt/data
	#/dev/nvme0n1p1        1G    1G        1G   1% /boot/efi
	#tmpfs                 3G    1G        3G   1% /run/user/1000	
}

proc job_server_stats::schedule {} {
	after 0 job_server_stats::job1
	after 0 job_server_stats::job2
}

proc job_server_stats::job1 {} {

	variable log

	try {
		job_server_stats::collect_proc_stats
	} on error err {
		${log}::debug "error run job collect_proc_stats: $err"
	}

	after 10000 job_server_stats::job1
}

proc job_server_stats::job2 {} {
	variable log

	try {
		job_server_stats::collect_disk_stats
	} on error err {
		${log}::debug "error run job collect_disk_stats: $err"
	}

	after 10000 job_server_stats::job2
}