#
#
class hosting_packages::dotcloud {
    
    $dotcloud  = ["dotcloud"]
    
    
    package { $dotcloud:
        ensure => installed,
        require => [Class["yumrepos::epel"],Class["yumrepos::koding"]],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
