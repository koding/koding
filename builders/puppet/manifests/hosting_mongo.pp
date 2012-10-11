node mongo  inherits base {
    include dblvm
    include munin
    include ssh
    include sudo
    
    yumrepos { 'koding':
        repo => 'koding',
    }
      resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.service.aws.koding.com',
        search => 'beta.service.aws.koding.com',
    }

 
    
    resources { "host":
       purge => true,
       #noop => true,
    }
    # cluster ip addresses
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    
}

node /^mongo\d+\.beta\.service\.aws\.koding\.com$/  inherits mongo {
    include mongodb
}

node /^mongo\d+\-slave\.beta\.service\.aws\.koding\.com$/  inherits mongo {
    $system = false
    include mongodb-slave
}
