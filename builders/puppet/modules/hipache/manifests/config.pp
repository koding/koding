#
#
class hipache::config {
        file { "/opt/hipache/config.json":
            ensure => file,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            content => template("hipache/config.json.erb"),
            require => Class["hipache::install"],
            notify => Class["hipache::service"],
        }

            
    
        
    #file { "/etc/logrotate.d/hipache":
    #    ensure => file,
    #    source => "puppet:///modules/hipache/hipache_logrotate",
    #    owner  => 'root',
    #    group  => 'root',
    #    mode   => '0644',
    #}
}
