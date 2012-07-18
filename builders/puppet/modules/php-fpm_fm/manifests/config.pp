# Class: php-fpm_fm::config
#
#
class php-fpm_fm::config {
    file { "/etc/php-fpm.d/www.conf":
        ensure  => file,
        source  => "puppet:///modules/php-fpm_fm/etc/php-fpm.d/www.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["php-fpm_fm::install"],
        notify  => Class["php-fpm_fm::service"],
    }
    file { "/etc/php.ini":
        ensure  => file,
        source  => "puppet:///modules/php-fpm_fm/etc/php.ini",
        owner   => 'root',
        group   => 'root',
        require => Class["php-fpm_fm::install"],
        notify  => Class["php-fpm_fm::service"],
    }

}
