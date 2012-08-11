node bongo inherits base {
    $nodeuser = true # install nodejs system user for monit and for nas mount
    
    include ssh
    include sudo
    include nodejs_rpm
    #include deploy_from_s3

    
  
    
    if $nodeuser {
        group { "node":
            gid => '70',
        }
        user { "node":
            comment => "NodeJS system user",
            home => "/home/node",
            ensure => present,
            shell => "/bin/sh",
            uid => '70',
            gid => '70',
            managehome => 'true',
            require => Group['node']
        }
        
    }

    
    
   
    monit::nodeapp { "BongoServer":
          appname   => "BongoServer",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }
    monit::nodeapp { "Databases":
          appname   => "Databases",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }
    
    

    resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com', 
    }
    
   # always test with noop first!
    resources { "host":
       purge => true,
       #noop => true,
    }    
    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

}

node /^bs\d+\.prod\.system\.aws\.koding\.com$/ inherits bongo {

}

node "bs1.beta.system.aws.koding.com" inherits bongo {
      include gluster_client
      include nfs_client
      #include cachefilesd
      bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

}

