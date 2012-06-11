class hosting_mysql_lvm::mount {

    file { "/var/lib/mysql/data/":
      ensure => directory,
      owner => "root",
      group => "root",
      require => Package["mysql-server"]
    }
    
    file { "/var/lib/mysql/binlogs/":
        ensure => directory,
        owner => "mysql",
        group => "mysql",
        require => Package["mysql-server"]
     }

    mount {"mount_fs_mysql":
        atboot  => true,
        ensure  => mounted,
        fstype  => "ext4",
        device  => "/dev/vg0/fs_mysql",
        name    => "/var/lib/mysql/data",
        options => "defaults,noatime",
        remounts => true,
        target  => '/etc/fstab',
        require  => [Class["hosting_mysql_lvm::create_lvm"],File["/var/lib/mysql/data"]],
    }
    
    file { "/var/lib/mysql/data/dbs":
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        require => Mount["mount_fs_mysql"]
    }
    
    mount {"mount_fs_binlogs":
        atboot  => true,
        ensure  => mounted,
        fstype  => "ext4",
        device  => "/dev/vg0/fs_binlogs",
        name    => "/var/lib/mysql/binlogs",
        options => "defaults,noatime",
        remounts => true,
        target  => '/etc/fstab',
        require  => [Class["hosting_mysql_lvm::create_lvm"],File["/var/lib/mysql/binlogs"]],
        notify  => Exec["binglogs_owner"]
    }
    
    exec { "binglogs_owner":
          command => "/bin/chown mysql:mysql /var/lib/mysql/binlogs",
          refreshonly => true,
          require => Mount["mount_fs_binlogs"],
    }
    

}
