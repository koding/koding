node mysql  inherits base {
    include hosting_mysql_lvm
    include ssh
    include sudo

    
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
    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}
}

node /^mysql\d+\.beta\.service\.aws\.koding\.com$/  inherits mysql {
    $master = true
    include hosting_mysql

}


node /^mysql\d+\-slave\.beta\.service\.aws\.koding\.com$/  inherits mysql {
    $master = false
    include hosting_mysql

}

