#
#
class hosting_packages::compilers {
    
    $compilers  = ["gcc", "gcc-c++", "make" ]
    
    
    package { $compilers:
        ensure => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
