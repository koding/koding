
class hosting_packages::fun {
    
    
    $fun = ["cowsay"]
    
    package { $fun:
        ensure  => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
    
}
