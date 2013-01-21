# Define: hosts
# Parameters:
# arguments
#
define hosts_file ($ipaddr,$aliases) {
    
    host {"$name":
        ensure => "present",
        ip => $ipaddr,
        host_aliases => $aliases,
    }
}
