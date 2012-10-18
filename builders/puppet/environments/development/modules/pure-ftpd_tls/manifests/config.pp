# Class: nginx::config
#
#
class pure-ftpd_tls::config {
    file { "main_conf":
        path    => '/etc/pure-ftpd/pure-ftpd.conf',
        ensure  => file,
        #source  => "puppet:///modules/pure-ftpd_tls/etc/pure-ftpd_tls/pure-ftpd_tls.conf",
        content => template("pure-ftpd_tls/pure-ftpd.conf.erb"),
        owner   => 'root',
        group   => 'root',
        require => Class["pure-ftpd_tls::install"],
        notify  => Class["pure-ftpd_tls::service"],
    }

    file { "cert":
        path    => '/etc/pki/pure-ftpd/pure-ftpd.pem',
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode => 0400,
        source  => "puppet:///modules/pure-ftpd_tls/etc/pki/pure-ftpd/pure-ftpd.pem",
        require => Class["pure-ftpd_tls::install"],
        notify  => Class["pure-ftpd_tls::service"],
    }
    

}
