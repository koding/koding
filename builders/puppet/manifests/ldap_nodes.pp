
node ldap inherits base {
    
    include ssh

    package { ["389-ds","perl-LDAP"]:
        ensure => "installed",
    }

    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    
}

node /^ldap\d+\.beta\.system\.aws\.koding\.com$/  inherits ldap {
   resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }


}    
node /^ldap\d+\.prod\.system\.aws\.koding\.com$/  inherits ldap {
   resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'prod.system.aws.koding.com',
        search => 'prod.system.aws.koding.com',
    }


}   
