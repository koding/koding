# Class: nginx::config
#
#
class admin_nginx::config {
    file { "main_conf":
        path    => '/etc/nginx/nginx.conf',
        ensure  => file,
        source  => "puppet:///modules/admin_nginx/etc/nginx.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["admin_nginx::install"],
        notify  => Class["admin_nginx::service"],
    }
    
    file { "/etc/nginx/conf.d/vhosts.conf":
        ensure  => file,
        source  => "puppet:///modules/admin_nginx/etc/conf.d/vhosts.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["admin_nginx::install"],File['main_conf']],
        notify  => Class["admin_nginx::service"],
    }
    file { "/etc/nginx/conf.d/htpasswd":
        ensure  => file,
        source  => "puppet:///modules/admin_nginx/etc/conf.d/htpasswd",
        owner   => 'root',
        group   => 'root',
        require => [Class["admin_nginx::install"],File['main_conf']],
        notify  => Class["admin_nginx::service"],
    }

}
