# Class: stunnel::monit
#
#
class stunnel::monit {
    file { "/etc/monit.d/stunnel":
        ensure => file,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/stunnel/etc/monit.d/stunnel",
        require => Class["monit::install"],
        notify  => Class["monit::service"]
    }
}