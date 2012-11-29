# Class: base_mysql::service
#
#
class base_mysql::service {
        service { "mysqld":
            ensure     => running,
            hasstatus  => true,
            hasrestart => true,
            enable     => true,
            require    => Class["base_mysql::config"],
        }
}