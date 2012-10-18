class hosting_mysql_lvm::create_lvm {
    
 
     
     file { "create_lvm.sh":
         path  => "/tmp/create_lvm.sh",
         owner => "root",
         group => "root",
         mode => 0700,
         source => "puppet:///modules/hosting_mysql_lvm/create_lvm.sh",
         notify => Exec["create_lvm"],
    }
    
    exec { "create_lvm":
        command => "/tmp/create_lvm.sh",
        require => File["create_lvm.sh"],
        onlyif => "/usr/bin/test -f /etc/new_server && /usr/bin/test ! -b /dev/vg0/fs_mysql",
        logoutput => "on_failure",
        refreshonly => true,
    }
    
    
}
