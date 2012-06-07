# Class: cloudlinux::
#
#
class cloudlinux::cagefs_update {
    
    exec { "/usr/sbin/cagefsctl":
        command => "/usr/sbin/cagefsctl --update",
        refreshonly => true,
        timeout => 0,
        onlyif => "/usr/bin/test -d /usr/share/cagefs-skeleton/"
    }
    
}
