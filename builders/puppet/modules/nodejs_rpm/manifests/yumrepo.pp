class nodejs_rpm::yumrepo {
    $gpg_key = "RPM-GPG-KEY-tchol"
    
    yumrepo { "nodejs":
        mirrorlist=>'http://nodejs.tchol.org/mirrors/nodejs-stable-el$releasever',
        descr => "Stable releases of Node.js",
        enabled => "1",
        gpgcheck => "1",
        gpgkey => "file:///etc/pki/rpm-gpg/$gpg_key",
        notify => File["nodejs_key"]
    }
    file { "nodejs_key":
        ensure => file,
        owner => "root",
        group => "root",
        mode => 0700,
        path => "/etc/pki/rpm-gpg/$gpg_key",
        source => "puppet:///modules/nodejs_rpm/gpg-keys/$gpg_key",
        require => Yumrepo["nodejs"],
        notify => Exec["install_nodejs_key"]
    }
    
    exec { "install_nodejs_key":
        command => "/bin/rpm --import /etc/pki/rpm-gpg/$gpg_key",
        subscribe => File["nodejs_key"],
        require => File["nodejs_key"],
        refreshonly => true,
        logoutput => "on_failure",
    }
}
