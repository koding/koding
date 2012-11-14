
class disabled_services::with_init {

    $disabled = [
        "restorecond",
        "auditd",
        "rhnsd",
        "smartd",
        "cpuspeed",
        "acpid",
        "ip6tables",
        "kdump",
        "haldaemon",
    ]

    service { $disabled:
        ensure => "false",
    }
    

}
