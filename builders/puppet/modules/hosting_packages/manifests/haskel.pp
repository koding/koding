#
#
class hosting_packages::haskel {
    
    $haskel  = ["haskell-platform.x86_64"]
    
    
    package { $haskel:
        ensure => installed,
        require => [Class["yumrepos::epel"],Class["yumrepos::koding"]],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
