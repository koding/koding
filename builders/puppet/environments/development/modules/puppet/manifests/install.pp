# Class: puppet::install
#
#
class puppet::install {
    
    
    package { "puppet":
        ensure => latest,
        notify => Service["puppet"],
    }
}
