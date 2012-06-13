class dblvm::create_dblvm {
    
 
     
     file { "create_dblvm.sh":
         path  => "/tmp/create_dblvm.sh",
         owner => "root",
         group => "root",
         mode => 0700,
         source => "puppet:///modules/dblvm/create_dblvm.sh",
         notify => Exec["create_dblvm"],
    }
    
    exec { "create_dblvm":
        command => "/tmp/create_dblvm.sh",
        require => File["create_dblvm.sh"],
        onlyif => "/usr/bin/test -f /etc/new_server && /usr/bin/test ! -b /dev/vg0/fs_mongo",
        logoutput => "on_failure",
        refreshonly => true,
    }
    
    
}
