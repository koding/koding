class ftp_crontabs::clamav {
    cron { "/usr/bin/freshclam --quiet": 
        user    => root,
        hour    => */8,
        minute  => 0,
        require => [Class["clamav::install"],Class["clamav::service"]]
    }
}
