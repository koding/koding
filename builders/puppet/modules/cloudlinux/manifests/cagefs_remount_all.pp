# Class: cloudlinux::
#
#
class cloudlinux::cagefs_remount_all {
    
    exec { "/usr/sbin/cagefsctl --remount-all":
        refreshonly => true,
        timeout => 0,
    }
    
}
