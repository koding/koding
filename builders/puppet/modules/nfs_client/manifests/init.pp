class nfs_client {

    package { "nfs-utils":
        ensure => installed,
    }
    service { "rpcbind":
        ensure => running,
        enable => true,
    }

    service { [ "nfslock" ]:
        ensure => running,
        enable => true,
        require => [Package["nfs-utils"],Service['rpcbind']],
    }

}

