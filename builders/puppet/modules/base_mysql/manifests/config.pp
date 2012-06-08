# Class: base_mysql::config
#
#
class base_mysql::config {
    file { "/etc/my.cnf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/base_mysql/etc/my.cnf',
        require => Class["base_mysql::install"],
        notify  => Class["base_mysql::service"],
    }
}