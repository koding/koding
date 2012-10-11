# Class: redis::install
#
#
class hipache::install {
    
    package { "hipache":
        ensure => installed,
        require => Class["yumrepos::koding"]
    }
        

}
