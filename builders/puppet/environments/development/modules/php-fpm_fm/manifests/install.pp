# Class: php-fpm_fm::install
#
#
class php-fpm_fm::install {
    
    $php = ["php54","php54-fpm","php54-ldap","php54-process","php54-mysql","php54-pear","php54-devel","gcc"]
    
    package { $php:
        ensure => installed,
        notify => Service['php-fpm']
    }


    # pecl extentions
    exec { "install_pecl_mongo":
        command => "/usr/bin/printf \"\n\" | /usr/bin/pecl -d preferred_state='stable' install mongo",
        unless => "/usr/bin/pecl info mongo",
        require => Package["php54-pear","php54-devel"],
    }
    file { "/etc/php.d/mongo.ini":
       content => "extension=mongo.so", 
       require => Exec["install_pecl_mongo"],
       notify => Service['php-fpm'],
    }
        

}
