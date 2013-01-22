#
#
class hosting_packages::compilers {
    
    $compilers  = ["gcc", "gcc-c++", "make", "go" ]
    
    
    package { $compilers:
        ensure => installed,
        require => [Class["yumrepos::epel"],Class["yumrepos::koding"]],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
