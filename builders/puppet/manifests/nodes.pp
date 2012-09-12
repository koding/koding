
node base {
    yumrepos { 'zabbixzone':
        repo => 'zabbixzone',
    }

    yumrepos { 'epel':
        repo => 'epel',
    }

    include motd
    include puppet
    include timezone
    # install and configure sudo
    include ntpd
    include zabbix-agent
    
    # sysadmins users accounts
    user { "root":
        ensure => present,
        uid => 0 ,
        gid => 0,
        password=> '$1$OYg431mU$j8A6rAnHFpmrUarifHyck1',
    }

    import "sysadmins/*"
  
     #service { "iptables":
	 #   ensure => stopped,
   	 #   hasstatus => true,
     #   hasrestart => true,
  	 #   enable => true,
     #}
     
     service { "cups":
	    ensure => stopped,
   	    hasstatus => true,
        hasrestart => true,
  	    enable => false,
     }
 
    
    # basic packages
    package { [ "vim-enhanced",
                "screen",
                "telnet",
                "iotop",
                "parted.x86_64",
                "sysstat",
                "rsync",
                "nano",
                "wget",
                "curl",
                "perl-Digest-SHA1.x86_64",
                "perl-Digest-HMAC.noarch",
                "python-boto.noarch",
                "python-argparse.noarch",
                ]:
            ensure => present,
            require => Class["yumrepos::epel"],
            }
            

        
}

import 'hosting_nodes.pp'
import 'bongo-server_nodes.pp'
import 'nginx_nodes.pp'
import 'web_nodes.pp'
import 'smtprelay_nodes.pp'
import 'sysmongo.pp'
import 'hosting_mysql.pp'
import 'hosting_mongo.pp'
import 'admin.pp'
import 'ldap_nodes.pp'
import 'ftp_nodes.pp'
import 'api_nodes.pp'
import 'gluster_nodes.pp'
import 'fm_nodes.pp'
import 'hipache_nodes.pp'
