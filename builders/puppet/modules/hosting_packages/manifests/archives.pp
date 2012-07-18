
class hosting_packages::archives {
    
    
    $archives = ["zip","unzip","p7zip"]
    
    package { $archives:
        ensure  => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
    
}
