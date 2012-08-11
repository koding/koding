# Class: httpd::install
#
#
class httpd::install {
    
    $php = ["php","php-mysql"]
    
    package { "httpd":
        ensure => latest,
    }
    package { $php:
        ensure => latest,
    }
}