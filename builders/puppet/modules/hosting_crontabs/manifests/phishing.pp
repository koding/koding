class hosting_crontabs::phishing {

    file { "/opt/cronscripts/phish.py":
         ensure  => file,
         source  => "puppet:///modules/hosting_crontabs/opt/cronscripts/phish.py",
         mode    => 755,
         require => Class["hosting_crontabs::scripts_dir"],
    }

    cron { phishing_db_update: 
        command => 'curl -s http://data.phishtank.com/data/ce48958df5a1352b676ef375f1c29fdce6f6ef039d33036a918c59430f3de7d9/online-valid.json > /tmp/online-valid.json && /opt/cronscripts/phish.py',
        user    => root,
        hour    => "*/1",
        minute  => 30,
        require => File['/opt/cronscripts/phish.py'],
    }


}
