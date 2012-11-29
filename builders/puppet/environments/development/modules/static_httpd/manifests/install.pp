# Class: static_httpd::install
#
#
class static_httpd::install {
    
    $php = ["php","php-pecl-mongo.x86_64","php-mysql","php-ldap"]
    
    package { "httpd":
        ensure => installed,
    }
    package { $php:
        ensure => installed,
        notify => Service["httpd"];
    }
}
