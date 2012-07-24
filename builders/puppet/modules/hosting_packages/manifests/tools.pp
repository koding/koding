
class hosting_packages::tools {
    
    
    $tools = ["htop","mc","bash-completion"]
    
    package { $tools:
        ensure  => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
    
}
