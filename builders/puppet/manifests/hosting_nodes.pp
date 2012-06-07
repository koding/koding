
node hosting inherits base {

    $nodeuser = true # install nodejs system user for monit and for nas mount
    
    
    #include initiallvm # create partition for /Users and mount

    include hosting_configs
    include sudo
    include hosting_packages
    include hosting_ssh
    include postfix 
    include nodejs_rpm

    include cloudlinux

    #include deploy_from_s3

    #include nfs_server
    
    if $nodeuser {
        group { "node":
            gid => '70',
        }
        user { "node":
            comment => "NodeJS system user",
            home => "/home/node",
            managehome => 'true',
            ensure => present,
            shell => "/bin/sh",
            uid => '70',
            gid => '70',
            require => Group['node']
        }
        
        
    }
    
   #resolve { "resolver":
   #     nameserver1 => '172.16.0.23',
   #     nameserver2 => '8.8.8.8',
   #     domain => 'beta.service.aws.koding.com',
   #     search => 'beta.service.aws.koding.com',
   # }


    # always test with noop first!
    resources { "host":
       purge => true,
       #noop => true,
    }    
    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}
    #

    $term_built_deps = ['bzip2-devel.x86_64','zlib-devel.x86_64']
    package { $term_built_deps:
	ensure => 'present',
    }

   
    
    # group for freeusers
    
    group { "freeusers":
        gid => 65,
    }
    
}


node 'cl1.beta.service.aws.koding.com' inherits hosting {
    #include litespeed
    include hosting_httpd
    include nfs_client 
    include gluster_client
    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}

#    monit::nodeapp { "SharedHosting":
#        appname   => "SharedHosting",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
#    
#    monit::nodeapp { "FsWatcher":
#        appname   => "FsWatcher",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
     # shared hosting servers
    #lsws_license {"serial": serial_no => 'F/P+-BNPP-z44/-1tKI' }
   
}

node 'cl2.beta.service.aws.koding.com' inherits hosting {
    include deploy_from_s3 # deployment disabled , just install tools
    include gluster_client
    #include litespeed
    include nfs_client
    #include cachefilesd
    include hosting_httpd
    include authconfig

    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
    bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

    monit::nodeapp { "TerminalJS":
        appname   => "TerminalJS",
        isenabled => 'enabled',
        nodeuser  => false,
        require_deploy => false,
    }
    monit::nodeapp { "SharedHosting":
        appname   => "SharedHosting",
        isenabled => 'enabled', 
        nodeuser  => false,
        require_deploy => false,
    }
    monit::nodeapp { "Databases":
          appname   => "Databases",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }
     monit::nodeapp { "pinger":
          appname   => "pinger",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }
 
#    monit::nodeapp { "FsWatcher":
#        appname   => "FsWatcher",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
    

    #lsws_license {"serial": serial_no => '9p9d-uLVj-kFIE-QBMM' }

}




node 'cl3.beta.service.aws.koding.com' inherits hosting {
    include deploy_from_s3 # deployment disabled , just install tools
    include gluster_client
    #include litespeed
    include nfs_client
    #include cachefilesd
    include hosting_httpd
    include authconfig

    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
    bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

#    monit::nodeapp { "TerminalJS":
#        appname   => "TerminalJS",
#        isenabled => 'enabled',
#        nodeuser  => false,
#        require_deploy => false,
#    }
#    monit::nodeapp { "SharedHosting":
#        appname   => "SharedHosting",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
#    
#    monit::nodeapp { "FsWatcher":
#        appname   => "FsWatcher",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
    

    #lsws_license {"serial": serial_no => '9p9d-uLVj-kFIE-QBMM' }

}

node 'cl4.beta.service.aws.koding.com' inherits hosting {
    include deploy_from_s3 # deployment disabled , just install tools
    include gluster_client
    #include litespeed
    include nfs_client
    #include cachefilesd
    include hosting_httpd
    include authconfig

    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
    bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

}

node 'cl5.beta.service.aws.koding.com' inherits hosting {
    include deploy_from_s3 # deployment disabled , just install tools
    include gluster_client
    #include litespeed
    #include nfs_client
    #include cachefilesd
    include hosting_httpd
    include authconfig

    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
    bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

    monit::nodeapp { "TerminalJS":
        appname   => "TerminalJS",
        isenabled => 'enabled',
        nodeuser  => false,
        require_deploy => false,
    }
    monit::nodeapp { "SharedHosting":
        appname   => "SharedHosting",
        isenabled => 'enabled', 
        nodeuser  => false,
        require_deploy => false,
    }
    monit::nodeapp { "Databases":
          appname   => "Databases",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }
 
#    monit::nodeapp { "FsWatcher":
#        appname   => "FsWatcher",
#        isenabled => 'enabled', 
#        nodeuser  => false,
#        require_deploy => false,
#    }
    

    #lsws_license {"serial": serial_no => '9p9d-uLVj-kFIE-QBMM' }

}



