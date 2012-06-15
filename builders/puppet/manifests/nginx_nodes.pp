node nginx inherits base {
    # nginx proxy servers
    #include deploy_from_s3 
    include nodejs_rpm
    include sudo
    include ssh

    include nginx_proxy

    $nodeuser = true # install nodejs system user for monit and for nas mount

#    if $nodeuser {
#        group { "node":
#            gid => '70',
#        }
#        user { "node":
#            comment => "NodeJS system user",
#                    home => "/home/node",
#                    ensure => present,
#                    shell => "/bin/sh",
#                    uid => '70',
#                    gid => '70',
#                    managehome => 'true',
#                    require => Group['node']
#        }
#
#    }
#
#    monit::nodeapp { "NginX":
#        appname   => "NginX",
#        isenabled => 'enabled',
#        nodeuser  => false,
#        require_deploy => false,
#    }
#

    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.service.aws.koding.com',
        search => 'beta.service.aws.koding.com',
    }

}

node /^proxy\d+\.beta\.system\.aws\.koding\.com$/  inherits nginx {
    include gluster_client
    bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
}
