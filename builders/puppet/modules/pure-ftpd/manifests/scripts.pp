#
#
class pure-ftpd::scripts {
    package { "nc":
        ensure => latest,
    }

    file { "clamav_check":
        path    => '/etc/pure-ftpd/clamav_check.sh',
        ensure  => file,
        source  => "puppet:///modules/pure-ftpd/etc/pure-ftpd/clamav_check.sh",
        owner   => 'root',
        group   => 'root',
        mode    => 0755,
        require => [Package["nc"],Class["pure-ftpd::install"]],
        notify  => Class["pure-ftpd::service"],
    }
    

}
