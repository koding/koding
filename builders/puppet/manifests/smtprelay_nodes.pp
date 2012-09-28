node relay inherits base {

    include mail_relay
    include cluebringer
    include sudo
    include httpd
    include ssh

    yumrepos { 'koding':
            repo => 'koding',
    }

    base_mysql::createdb { "cluebringer":
         rootpw => 'ti-ka-phe-zex',
         user     => "cluebringer",
         password => 'hurh-sha-thax'
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

#node 'relay0.beta.system.aws.koding.com' inherits relay {
#}

node 'relay1.beta.system.aws.koding.com' inherits relay {
}
