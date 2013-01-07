class hosting_crontabs::clamav {

    cron { clamav_scan: 
        ensure  => absent,
        command => '/usr/bin/ionice -c 3 -p `cat /var/run/clamav/clamd.pid` ; /bin/echo -e "MULTISCAN /Users" | /usr/bin/nc localhost 13310',
        user    => root,
        hour    => 2,
        minute  => 30,
        require => [Class["clamav::install"],Class["clamav::service"]]
    }

}
