cron { clamav_scan: 
    command => "/usr/bin/freshclam --quiet ;  /bin/echo -e "RELOAD" | /usr/bin/nc localhost 3310 ; /bin/sleep 10; /usr/bin/ionice -c 3 -p `cat /var/run/clamav/clamd.pid` ; /bin/echo -e "MULTISCAN /Users" | /usr/bin/nc localhost 3310",
    user    => root,
    hour    => 2,
    minute  => 30,
    require => [Class["hosting_clamav::install"],Class["hosting_clamav::service"]]
}
