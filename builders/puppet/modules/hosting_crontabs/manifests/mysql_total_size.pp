class hosting_crontabs::mysql_total_size {

    file { "/opt/cronscripts/mysql_total_size.sh":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/mysql_total_size.sh",
         mode    => 700,
         require => Class["hosting_crontabs::scripts_dir"],
    }

    cron { mysql_total_size: 
        command => "/opt/cronscripts/crmysql_total_size.sh",
        user    => root,
        minute  => ['*/43'],
        require => File['/opt/cronscripts/mysql_total_size.sh'],
    }


}
