# Class: mongodb::config
#
#
class mongodb-slave::config {
    if $system {
        file { "/etc/mongod.conf":
            ensure => file,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            content => template("mongodb-slave/mongod.conf.erb"),
            require => Class["mongodb-slave::install"],
            notify => Class["mongodb-slave::service"],
        }
    }else{
        file { "/etc/mongod.conf":
            ensure => file,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            content => template("mongodb-slave/mongod_service.conf.erb"),
            require => Class["mongodb-slave::install"],
            notify => Class["mongodb-slave::service"],
        }
    }
    
    # http://www.mongodb.org/display/DOCS/Security+and+Authentication#SecurityandAuthentication-ReplicaSetandShardingAuthentication
    file { "/etc/secret_key":
        ensure => file,
        owner => "mongod",
        group => "mongod",
        mode  => '0400',
        source => "puppet:///modules/mongodb/secret_key",
        require => Class["mongodb-slave::install"],
        notify => Class["mongodb-slave::service"],
    }
    
    
    file { "/etc/logrotate.d/mongodb":
        ensure => file,
        source => "puppet:///modules/mongodb/mongodb_logrotate",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
