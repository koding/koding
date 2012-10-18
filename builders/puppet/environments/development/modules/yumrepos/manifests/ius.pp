class yumrepos::ius {
    $gpg_key = "IUS-COMMUNITY-GPG-KEY"
    
    yumrepo { "ius":
        #baseurl => "http://download.fedoraproject.org/pub/epel/6/$basearch",
        mirrorlist=>'http://dmirr.iuscommunity.org/mirrorlist/?repo=ius-el6&arch=$basearch',
        descr => "IUS repo",
        enabled => "1",
        gpgcheck => "1",
        gpgkey => "file:///etc/pki/rpm-gpg/$gpg_key",
        notify => File["ius_key"]
    }
    file { "ius_key":
        ensure => file,
        owner => "root",
        group => "root",
        mode => 0700,
        path => "/etc/pki/rpm-gpg/$gpg_key",
        source => "puppet:///modules/yumrepos/gpg-keys/$gpg_key",
        require => Yumrepo["ius"],
        notify => Exec["install_ius_key"]
    }
    
    exec { "install_ius_key":
        command => "/bin/rpm --import /etc/pki/rpm-gpg/$gpg_key",
        subscribe => File["ius_key"],
        require => File["ius_key"],
        refreshonly => true,
        logoutput => "on_failure",
    }
}
