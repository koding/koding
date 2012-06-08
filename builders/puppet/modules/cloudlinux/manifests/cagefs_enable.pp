# Class: cloudlinux::
#
#
class cloudlinux::cagefs_enable {
    
    exec { "cagefs_enableall":
        command => "/usr/sbin/cagefsctl --enable-all",
        timeout => 0,
        onlyif => "/usr/sbin/cagefsctl --display-user-mode | /bin/grep Disable"
    }
    
}
