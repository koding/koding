
#
class hosting_clamav::install {
    package { ['clamav-db','clamav','clamd','nc']:
        ensure => present,
    }
}
