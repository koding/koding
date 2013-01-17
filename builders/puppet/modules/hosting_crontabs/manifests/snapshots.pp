class hosting_crontabs::ebs_snapshots {

    file { "/opt/cronscripts/ebs_snapshots.py":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/ebs_snapshots.py",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }
    cron { ebs_snapshots:
        command => "/opt/cronscripts/ebs_snapshots.py",
        user    => root,
        minute  => "*/50",
        require => File['/opt/cronscripts/ebs_snapshots.py'],
    }

}
