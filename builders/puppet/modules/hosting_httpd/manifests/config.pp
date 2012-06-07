# Class: hosting_httpd::config
#
#
class hosting_httpd::config {
    File { 
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        require => Class["hosting_httpd::install"],
        notify  => Class["hosting_httpd::service"],
    }

    file { "/etc/httpd/conf/httpd.conf":
        ensure  => file,
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf/httpd.conf",
    }

    file { "/etc/php.ini":
        source  => "puppet:///modules/hosting_httpd/etc/php.ini",
    }

    file { "/etc/suphp.conf":
        source  => "puppet:///modules/hosting_httpd/etc/suphp.conf",
    }

    file { "/etc/httpd/conf.d/php.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/php.conf",
    }

    file { "/etc/httpd/conf.d/suphp.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/suphp.conf",
    }

    file { "/etc/httpd/conf.d/modhostinglimits.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/modhostinglimits.conf",
    }

    file { "/etc/sysconfig/httpd":
        source  => "puppet:///modules/hosting_httpd/etc/sysconfig/httpd",
    }
}

