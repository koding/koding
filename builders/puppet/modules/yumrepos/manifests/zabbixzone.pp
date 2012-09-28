class yumrepos::zabbixzone {
    $gpg_key = "RPM-GPG-KEY-zabbixzone"
    
    yumrepo { "zabbixzone":
        baseurl => 'http://repo.zabbixzone.com/centos/$releasever/$basearch/',
        descr => "CentOS $releasever - ZabbixZone",
        enabled => "1",
        gpgcheck => "1",
        gpgkey => "file:///etc/pki/rpm-gpg/$gpg_key",
        notify => File["zabbixzone_key"]
    }
    file { "zabbixzone_key":
        ensure => file,
        owner => "root",
        group => "root",
        mode => 0700,
        path => "/etc/pki/rpm-gpg/$gpg_key",
        source => "puppet:///modules/yumrepos/gpg-keys/$gpg_key",
        require => Yumrepo["zabbixzone"],
        notify => Exec["install_zabbixzone_key"]
    }
    
    exec { "install_zabbixzone_key":
        command => "/bin/rpm --import /etc/pki/rpm-gpg/$gpg_key",
        subscribe => File["zabbixzone_key"],
        require => File["zabbixzone_key"],
        refreshonly => true,
        logoutput => "on_failure",
    }
}
