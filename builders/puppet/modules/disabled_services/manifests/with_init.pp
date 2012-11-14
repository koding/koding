
class disabled_services::with_init {

    $disabled = [
        "restorecond",
        "auditd",
        "rhnsd",
        "smartd",
        "acpid",
        "ip6tables",
        "kdump",
        "haldaemon",
    ]

    service { $disabled:
	    provider => 'redhat',
        ensure => 'stopped',
	    enable => 'false',
    }
    

}
