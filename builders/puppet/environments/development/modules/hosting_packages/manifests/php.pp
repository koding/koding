
class hosting_packages::php {
    $php = ["php",
            "php-suhosin",
            "php-mysql",
            "php-gd",
            "php-pdo",
            "php-pecl-imagick",
            "php-mcrypt",
            "php-pgsql",
            "php-xmlrpc",
            "php-mbstring",
            "php-pecl-mongo",
            "php-cli",
            "php-xml",
            "php-dba",
            "php-pear",
        ] 
    
    package { $php :
        ensure => installed,
        require => [Class["yumrepos::epel"], Class["hosting_httpd"]],
        notify => Class["cloudlinux::cagefs_update"],
    }

    file { '/var/lib/php/session/':
        ensure  => directory,
        require => Package[$php],
        owner   => 'root',
        group   => 'apache',
        mode    => 1733,
    }
    
}
