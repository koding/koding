
#
class clamav::install {
    package { ['clamav-db','clamav','clamd','nc']:
        ensure => present,
        require => Class["yumrepos::epel"]
    }
}
