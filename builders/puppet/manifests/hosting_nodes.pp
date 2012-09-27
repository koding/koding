
node hosting inherits base {

    $nodeuser = true # install nodejs system user for monit and for nas mount

    yumrepos { 'koding':
        repo => 'koding',
    }
    yumrepos { 'erlang':
        repo => 'erlang',
    }


    include hosting_configs
    include hosting_crontabs
    include clamav
    include sudo
    include hosting_packages
    include hosting_ssh
    include postfix 
    include nodejs_rpm
    include cloudlinux

    
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
   
    # always test with noop first!
    resources { "host":
       purge => true,
       #noop => true,
    }    
    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    $term_built_deps = ['bzip2-devel.x86_64','zlib-devel.x86_64']
    
    package { $term_built_deps:
	    ensure => 'present',
    }

   
    
   
}

node /^cl\d+\.beta\.service\.aws\.koding\.com$/ inherits hosting {

    include deploy_from_s3 # deployment disabled , just install tools
    #include gluster_client
    #include nfs_client
    include hosting_httpd
    include authconfig
    include nginx_proxy

    #bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
    #bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

    monit::nodeapp { "terminal":
        appname   => "terminal",
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
 
}




