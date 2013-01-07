class hosting_crontabs::clamav {

    file { "/opt/cronscripts/clamscan.sh":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/clamscan.sh",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }


    cron { clamav_scan: 
        command => '/opt/cronscripts/clamscan.sh',
        user    => root,
        hour    => 2,
        minute  => 30,
        require => [Class["clamav::install"],Class["clamav::service"]]
    }

}
