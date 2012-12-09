class gluster_client::gluster_packages {
    package { ["glusterfs-fuse.x86_64","glusterfs.x86_64"]:
        ensure => present,
        require => Class["yumrepos::epel"],
    }
}
