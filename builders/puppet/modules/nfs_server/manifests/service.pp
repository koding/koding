class nfs_server::service {

    service { "rpcbind":
        ensure => running,
        enable => true,
    }

    service { [ "nfs", "nfslock" ]:
        ensure => running,
        enable => true,
        require => [Package["nfs-utils"],Service['rpcbind']],
    }
}

