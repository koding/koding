#
#
class pure-ftpd_tls::scripts {

    file { "clamav_check":
        path    => '/etc/pure-ftpd_tls/clamav_check.sh',
        ensure  => file,
        source  => "puppet:///modules/pure-ftpd_tls/etc/pure-ftpd/clamav_check.sh",
        owner   => 'root',
        group   => 'root',
        mode    => 0755,
        require => [Package["nc"],Class["pure-ftpd_tls::install"]],
        notify  => Class["pure-ftpd_tls::service"],
    }
    

}
