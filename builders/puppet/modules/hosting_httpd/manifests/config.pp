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

    file { "/etc/php.d/suhosin.ini":
        source  => "puppet:///modules/hosting_httpd/etc/php.d/suhosin.ini",
    }

    file { "/etc/php.d/prepend.php":
        source  => "puppet:///modules/hosting_httpd/etc/php.d/prepend.php",
    }



    file { "/etc/httpd/conf.d/php.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/php.conf",
    }
    
    file { "/etc/httpd/conf.d/fcgid.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/fcgid.conf",
    }
    

    file { "/etc/httpd/conf.d/modhostinglimits.conf":
        source  => "puppet:///modules/hosting_httpd/etc/httpd/conf.d/modhostinglimits.conf",
    }

    file { "/etc/sysconfig/httpd":
        source  => "puppet:///modules/hosting_httpd/etc/sysconfig/httpd",
    }
   
    file { "/usr/local/safe-bin/":
	ensure => "directory",
    }
    
    file { "/usr/local/safe-bin/php-wrapper":
	mode => "755",
	source  => "puppet:///modules/hosting_httpd/usr/local/safe-bin/php-wrapper",
        require => File["/usr/local/safe-bin/"],
	notify => Class["cloudlinux::cagefs_update"],
    }

    file { "/usr/bin/pear":
	    mode => "755",
	    source  => "puppet:///modules/hosting_httpd/usr/bin/pear",
        require => Class["hosting_packages::php"],
	    notify => Class["cloudlinux::cagefs_update"],
    }

}

