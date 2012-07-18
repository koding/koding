node /^db\d+\.beta\.system\.aws\.koding\.com$/  inherits base {
    #include dblvm
    include mongodb
    include munin
    include sudo
    include ssh
    
    resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }


    
    resources { "host":
       purge => true,
       #noop => true,
    }
    # cluster ip addresses
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    
}

node /^db\d+\-slave\.beta\.system\.aws\.koding\.com$/  inherits base {
    $system = true
    #include dblvm
    include mongodb-slave
    include munin

    resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }
    
    resources { "host":
       purge => true,
       #noop => true,
    }
    # cluster ip addresses
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    
}


