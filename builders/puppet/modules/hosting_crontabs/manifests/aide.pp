class hosting_crontabs::aide {

    cron { aide_scan: 
        command => '/usr/sbin/aide --check',
        user    => root,
        hour    => ['*/4'],
        minute  => 55,
        require => Class["aide::db_init"],
    }

}
