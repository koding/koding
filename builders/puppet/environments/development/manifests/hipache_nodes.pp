node hipache_nodes inherits base {

    include ssh
    include sudo 

    yumrepos { 'koding':
         repo => 'koding',
    }


    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }

}
 
node 'ip-10-85-62-69.ec2.internal' inherits hipache_nodes {
    include redis
    include hipache
}
 
