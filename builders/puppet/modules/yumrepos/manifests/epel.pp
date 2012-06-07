class yumrepos::epel {
    $gpg_key = "RPM-GPG-KEY-EPEL-6"
    
    yumrepo { "epel":
        #baseurl => "http://download.fedoraproject.org/pub/epel/6/$basearch",
        mirrorlist=>'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        descr => "The epel repository",
        enabled => "1",
        gpgcheck => "1",
        gpgkey => "file:///etc/pki/rpm-gpg/$gpg_key",
        notify => File["epel_key"]
    }
    file { "epel_key":
        ensure => file,
        owner => "root",
        group => "root",
        mode => 0700,
        path => "/etc/pki/rpm-gpg/$gpg_key",
        source => "puppet:///modules/yumrepos/gpg-keys/$gpg_key",
        require => Yumrepo["epel"],
        notify => Exec["install_key"]
    }
    
    exec { "install_key":
        command => "/bin/rpm --import /etc/pki/rpm-gpg/$gpg_key",
        subscribe => File["epel_key"],
        require => File["epel_key"],
        refreshonly => true,
        logoutput => "on_failure",
    }
}
