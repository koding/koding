class clamav::crontabs {
    cron { "clamav_update": 
        command => "/usr/bin/freshclam --quiet --daemon-notify",
        user    => root,
        hour    => '*/8',
        minute  => 0,
        require => [Class["clamav::install"],Class["clamav::service"]]
    }
}
