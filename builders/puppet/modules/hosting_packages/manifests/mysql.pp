
class hosting_packages::mysql {
    
    
    $mysql = ["mysql"]
    
    package { $mysql:
        ensure  => installed,
        notify => Class["cloudlinux::cagefs_update"]

    }
    
}
