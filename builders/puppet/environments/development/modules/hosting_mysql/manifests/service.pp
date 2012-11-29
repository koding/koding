class hosting_mysql::service {
    service { "mysqld":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => [Class["hosting_mysql::config"],Class["hosting_mysql_lvm::mount"]],
    }
}
