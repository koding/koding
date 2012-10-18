class hosting_crontabs::mysql_quota {

    file { "/opt/cronscripts/db_conf.py":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/db_conf.py",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }


    file { "/opt/cronscripts/db.py":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/db.py",
         mode    => 755,
         require => [Class["hosting_crontabs::scripts_dir"],File["/opt/cronscripts/db_conf.py"]],
    }

    cron { db_grant: 
        ensure => absent,
        command => "/opt/cronscripts/db.py --grant > /dev/null",
        user    => root,
        minute  => "*/5",
        require => File['/opt/cronscripts/db.py'],
    }
    cron { db_revoke: 
        ensure => absent,
        command => "/opt/cronscripts/db.py --revoke",
        user    => root,
        hour    => "*/1",
        minute  => 45,
        require => File['/opt/cronscripts/db.py'],
    }



}
