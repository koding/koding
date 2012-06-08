class gluster_client::mount {

    file { "/mnt/storage0":
        ensure => 'directory',
        owner => 'root',
        group => 'root',
    }


    mount {"mount_glusterfs":
        atboot  => true,
        ensure  => mounted,
        fstype  => "glusterfs",
        #fstype  => "nfs",
        device  => "disk0.prod.system.aws.koding.com:/storage0",
        name    => "/mnt/storage0",
        #options => "nodiratime,noatime,fsc,ac,vers=3,rsize=32768,wsize=32768,tcp,intr,async",
        options => "acl,log-level=WARNING,direct-io-mode=disable,_netdev",
        target  => '/etc/fstab',
        require => [File['/mnt/storage0'],Class['gluster_client::gluster_packages']]
    }


}
