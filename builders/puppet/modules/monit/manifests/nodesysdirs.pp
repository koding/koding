# Class: apps
#
#
class monit::nodesysdirs {
    
    
    
    file { "node_log_dir":
        path => "/var/log/node",
        ensure => directory,
    }
    file { "node_pid_dir":
        path => "/var/run/node",
        ensure => directory,
    }
    
    
    
}
