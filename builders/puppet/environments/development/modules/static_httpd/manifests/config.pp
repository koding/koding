# Class: static_httpd::config
#
#
class static_httpd::config {
    file { "/etc/httpd/conf/httpd.conf":
        ensure  => file,
        #source  => "puppet:///modules/static_httpd/etc/httpd/conf/httpd.conf",
        content => template("static_httpd/httpd.conf.erb"),
        owner   => 'root',
        group   => 'root',
        require => Class["static_httpd::install"],
        notify  => Class["static_httpd::service"],
    }
    file { "/etc/php.ini":
        ensure  => file,
        source  => "puppet:///modules/static_httpd/etc/php.ini",
        owner   => 'root',
        group   => 'root',
        require => Class["static_httpd::install"],
        notify  => Class["static_httpd::service"],
    }

}
