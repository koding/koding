# Class: nginx::config
#
#
class pure-ftpd::config {
    file { "main_conf":
        path    => '/etc/pure-ftpd/pure-ftpd.conf',
        ensure  => file,
        #source  => "puppet:///modules/pure-ftpd/etc/pure-ftpd/pure-ftpd.conf",
        content => template("pure-ftpd/pure-ftpd.conf.erb"),
        owner   => 'root',
        group   => 'root',
        require => Class["pure-ftpd::install"],
        notify  => Class["pure-ftpd::service"],
    }
    

}
