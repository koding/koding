# Class: hosting_packages::ruby
#
#
class hosting_packages::ftp {
    
    $ftp  = ["ftp","lftp.x86_64","lftp-scripts.noarch" ]
    
    
    package { $ftp:
        ensure => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
