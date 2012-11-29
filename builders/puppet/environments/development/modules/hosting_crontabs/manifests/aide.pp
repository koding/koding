class hosting_crontabs::aide {

    cron { aide_scan: 
        ensure => absent,
        command => '/usr/sbin/aide --check >> /var/log/aide.log ; echo  "UserParameter=aide.result,echo $?" > /etc/zabbix/zabbix_agentd.conf.d/aide_result.conf',
        user    => root,
        hour    => ['*/4'],
        minute  => 55,
        require => Class["aide::db_init"],
    }

}
