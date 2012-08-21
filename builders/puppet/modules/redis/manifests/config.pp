#
#
class redis::config {
        file { "/etc/redis.conf":
            ensure => file,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            content => template("redis/redis.conf.erb"),
            require => Class["redis::install"],
            notify => Class["redis::service"],
        }

            
    
        
    file { "/etc/logrotate.d/redis":
        ensure => file,
        source => "puppet:///modules/redis/redis_logrotate",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
