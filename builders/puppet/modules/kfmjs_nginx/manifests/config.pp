# Class: kfmjs_nginx::config
#
#
class kfmjs_nginx::config {
    file { "/etc/nginx/nginx.conf":
        ensure  => file,
        source  => "puppet:///modules/kfmjs_nginx/etc/nginx.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["kfmjs_nginx::install"],
        notify  => Class["kfmjs_nginx::service"],
    }
    
    file { "/etc/nginx/conf.d/koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/kfmjs_nginx/etc/conf.d/koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["kfmjs_nginx::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["kfmjs_nginx::service"],
    }
    
}
