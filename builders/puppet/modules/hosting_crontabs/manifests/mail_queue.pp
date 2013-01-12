class hosting_crontabs::mail_queue {

    file { "/opt/cronscripts/mail_queue.sh":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/mail_queue.sh",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }
    cron { mail_queue:
        command => "/opt/cronscripts/mail_queue.sh",
        user    => root,
        minute  => "*/5",
        require => File['/opt/cronscripts/mail_queue.sh'],
    }

}
