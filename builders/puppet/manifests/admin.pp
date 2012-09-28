
node adminnode inherits base {
    
   include admin_nginx
   include sudo 
   include gluster_client
   bind_dir { "/opt/kfmjs": mpoint => "/opt/kfmjs", device => "/mnt/storage0/kfmjs"}

   resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'prod.system.aws.koding.com',
        search => 'prod.system.aws.koding.com',
    }


    
    
    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    
}

node /^admin\.prod\.system\.aws\.koding\.com$/  inherits adminnode {
}    
