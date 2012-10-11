
node ftp inherits base {

   include sudo
   include pure-ftpd
   include ssh
   include clamav

    yumrepos { 'koding':
            repo => 'koding',
    }
   monit::nodeapp { "PureFTPDauth":
       appname   => "PureFTPDauth",
       isenabled => 'enabled',
       nodeuser  => false,
       require_deploy => false,
   }

   monit::nodeapp { "pure-uploadscript":
       appname   => "pure-uploadscript",
       isenabled => 'enabled',
       nodeuser  => false,
       require_deploy => false,
   }


   resolve { "resolver":
        nameserver1 => '172.16.0.23',
        nameserver2 => '8.8.8.8',
        domain => 'beta.system.aws.koding.com',
        search => 'beta.system.aws.koding.com',
    }


    hosts_file {"$fqdn": ipaddr=> $ipaddress_eth0, aliases=>$hostname}
    hosts_file {"localhost.localdomain": ipaddr=>"127.0.0.1",aliases=>"localhost"}

    
}

node /^ftp\d+\.prod\.service\.aws\.koding\.com$/  inherits ftp {
}    
node /^ftp\d+\.beta\.service\.aws\.koding\.com$/  inherits ftp {
}   
node "ftp1.beta.service.aws.koding.com"  inherits ftp {
#    include gluster_client
    include nfs_client

 #   bind_dir { "/Users": mpoint => "/Users", device => "/mnt/storage0/Users"}
}   
