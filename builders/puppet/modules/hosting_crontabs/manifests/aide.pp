class hosting_crontabs::aide {

    file { "/opt/cronscripts/aide.sh":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/aide.sh",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }

    cron { aide_scan: 
        command => "/opt/cronscripts/aide.sh",
        user    => root,
        hour    => ['*/4'],
        minute  => 55,
        require => [Class["aide::db_init"],File["/opt/cronscripts/aide.sh"]],
    }

}
