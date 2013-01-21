
class hosting_packages::mysql {
    
    
    $mysql = ["mysql","mysql-devel"]
    
    package { $mysql:
        ensure  => installed,
        notify => Class["cloudlinux::cagefs_update"]

    }
    
}
