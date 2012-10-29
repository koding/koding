#
#
class nfs_server::config {

    File { 
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => 0644,
        require => Class["nfs_server::install"],
        notify  => Class["nfs_server::service"],
    }

    file { "/etc/sysconfig/nfs":
        ensure  => file,
        source  => "puppet:///modules/nfs_server/etc/sysconfig/nfs",
    }


}

