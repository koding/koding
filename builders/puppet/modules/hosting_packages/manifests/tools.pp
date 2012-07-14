
class hosting_packages::tools {
    
    
    $tools = ["htop","mc"]
    
    package { $tools:
        ensure  => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
    
}
