class initiallvm::create_fs {
    
    file { "Users":
       path    => '/Users',
       owner  => "root",
       group  => "root",
       mode  => 755,
       ensure => "directory",
       notify => File["create_lvm.sh"],
       require => Class["initiallvm::xfs_packages"],
     }
     
     file { "create_lvm.sh":
         path  => "/tmp/create_lvm.sh",
         owner => "root",
         group => "root",
         mode => 0700,
         source => "puppet:///modules/initiallvm/create_lvm.sh",
         require => File["Users"],
         notify => Exec["create_lvm"],
    }
    
    exec { "create_lvm":
        command => "/tmp/create_lvm.sh",
        require => File["create_lvm.sh"],
        onlyif => "/usr/bin/test -f /etc/new_server",
        logoutput => "on_failure",
        refreshonly => true,
    }
    
    
}
