
#
class clamav::install {
    package { ['clamav-db','clamav','clamd','nc']:
        ensure => present,
        require => Class["yumrepos::koding"],
        notify => Class["clamav::initial_update"],
    }
}
