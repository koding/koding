# Define: node::installmonit
# Parameters:
# arguments
#
define monit::nodeapp ($appname,$isenabled,$nodeuser,$require_deploy) {
    # puppet code
    
    include monit::install, monit::config, monit::service,monit::nodesysdirs
    
    # for node sysdirs
    if $nodeuser {
        File {
            mode => "0750",
            owner => "node",
            group => "node",
        }
    } else {
        File {
            mode => "0750",
            owner => "root",
            group => "root",
        }
    }
    
    
    
    file { "$appname":
        ensure => $isenabled ? {
            enabled  => file,
            disabled => absent,
        },
        path => "/etc/monit.d/scripts/$appname.sh",
        source => "puppet:///modules/monit/etc/monit.d/scripts/$appname.sh",
        require => Class["monit::nodesysdirs"]
    }

    file { "monitconf_$appname":
        ensure => $isenabled ? {
            enabled  => file,
            disabled => absent,
        },
        mode => "0600",
        owner => "root",
        group => "root",
        path => "/etc/monit.d/$appname",
        source => "puppet:///modules/monit/etc/monit.d/$appname",
        notify => Exec["$appname"],
        require => $nodeuser ? {
            true => [User["node"],File["$appname"]],
            false=> File["$appname"] 
        }
    }
    
    exec { "$appname":
        command => "/sbin/service monit restart",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
        subscribe => File["monitconf_$appname"],
        logoutput => "on_failure",
        #require   => Class['mount_nas']
        #require => [Class["gluster_client"],Class["nodejs_rpm::install"]]
        #require => Class["nodejs_rpm::install"]
    }

}

