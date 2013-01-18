class hosting_crontabs::gem_update {

    file { "/opt/cronscripts/gem_update.sh":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/gem_update.sh",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }
    cron { gem_update:
        command => "/opt/cronscripts/gem_update.sh",
        user    => root,
        minute  => "*/15",
        require => File['/opt/cronscripts/gem_update.sh'],
    }

}
