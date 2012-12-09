#
#
class rsyslog::config {

    File {
        ensure => present,
        owner  => 'root',
        group  => 'root',
        require => Class["rsyslog::install"],
    }

    file { "/etc/logrotate.d/syslog":
        source  => "puppet:///modules/rsyslog/etc/logrotate.d/syslog",
    }
    file { "/etc/rsyslog.conf":
        source  => "puppet:///modules/rsyslog/etc/rsyslog.conf",
        notify  => Service["rsyslog"],
    }
    file { "/etc/sysconfig/rsyslog":
        source  => "puppet:///modules/rsyslog/etc/sysconfig/rsyslog",
        notify  => Service["rsyslog"],
    }

}
