
node webnode inherits base {
    # nginx proxy servers
    $nodeuser = true # install nodejs system user for monit and for nas mount
    
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
    
    
    yumrepos { 'koding':
        repo => 'koding',
    }
    yumrepos { 'erlang':
        repo => 'erlang',
    }


    include nodejs_rpm
    include rabbitmq
    #include mount_nas
    #include stunnel
    include ssh
    include sudo
    include kfmjs_nginx
    include static_httpd
    #include deployment_script
    #include deploy_from_s3
    
   resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }


    
    # build kd-server.js
    package { "git":
	    ensure => present,
    }   
    #exec { "build":
    #    cwd     => '/opt/kfmjs',
    #    command => "/usr/bin/cake -sd beta build && /bin/cp /tmp/kd-server.js /opt/kfmjs/",
    #    onlyif  => "/usr/bin/test ! -e /opt/kfmjs/kd-server.js",
    #    require => [Class["deploy_from_s3::deploy"],Package["git"]],
    #    logoutput => true,
    #}
    
#    monit::nodeapp { "koding":
#        appname   => "koding",
#        isenabled => 'enabled', 
#        nodeuser  => true,
#        require_deploy => false,
#    }
#    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    
}

node /^web\d+\.dev\.system\.aws\.koding\.com$/  inherits webnode {
}    

node /^web\d+\.beta\.system\.aws\.koding\.com$/ inherits webnode {
       #include gluster_client
       #include nfs_client
       #include cachefilesd
      #bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}
      monit::nodeapp { "webCake":
          appname   => "webCake",
          isenabled => 'enabled',
          nodeuser  => true,
          require_deploy => false,
    }

}    

