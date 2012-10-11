# Class: puppet::config
#
#
class puppet::config {
    file { "/etc/puppet/puppet.conf":
        ensure  => file,
        source  => "puppet:///modules/puppet/etc/puppet/puppet.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["puppet::install"],
        notify  => Class["puppet::service"],
    }
    {
    file { "/etc/sysconfig/puppet":
        ensure  => file,
        source  => "puppet:///modules/puppet/etc/sysconfig/puppet",
        owner   => 'root',
        group   => 'root',
        require => Class["puppet::install"],
        notify  => Class["puppet::service"],
    }

    
}
