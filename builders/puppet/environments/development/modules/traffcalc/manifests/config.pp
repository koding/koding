#
#
class traffcalc::config {
    file { "/etc/sysconfig/traffic":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        source => 'puppet:///modules/traffcalc/etc/sysconfig/traffic',
        require => Class["traffcalc::install"],
        notify  => Class["traffcalc::service"],
    }
}
