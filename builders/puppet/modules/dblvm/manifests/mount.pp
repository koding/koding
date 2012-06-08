class dblvm::mount {

    file { "/var/lib/mongo":
      ensure => directory,
      owner => "mongod",
      group => "mongod",
      require => Package["mongo-10gen-server"]
    }

    mount {"mount_fs_mongo":
        atboot  => true,
        ensure  => mounted,
        fstype  => "ext4",
        device  => "/dev/vg0/fs_mongo",
        name    => "/var/lib/mongo",
        options => "defaults,noatime",
        remounts => true,
        target  => '/etc/fstab',
        require  => [Class["dblvm::create_dblvm"],File["/var/lib/mongo"]],
        notify  => Exec["mpoint_owner"]
    }
    
    exec { "mpoint_owner":
        command => "/bin/chown mongod:mongod /var/lib/mongo",
        refreshonly => true,
        require => Mount["mount_fs_mongo"],
    }

}
