# Class: redis::install
#
#
class redis::install {
    
    package { "redis":
        ensure => installed,
        require => Class["yumrepos::epel"]
    }
        

}
