# Class: cluebringer::config
#
#
class cluebringer::config {
    File {
        owner => "root",
        group => "root",
    }
    
    
    file { "/etc/policyd/cluebringer.conf":
        ensure => file,
        source => "puppet:///modules/cluebringer/etc/policyd/cluebringer.conf",
        require => Class['cluebringer::install'],
        notify => Class['cluebringer::service'],
    }
    
    file { "/etc/policyd/webui.conf":
        ensure => file,
        source => "puppet:///modules/cluebringer/etc/policyd/webui.conf",
        require => Class['cluebringer::install'],
    }
    
    file { "/etc/httpd/conf.d/cluebringer.conf":
        ensure => file,
        source => "puppet:///modules/cluebringer/etc/httpd/conf.d/cluebringer.conf",
        require => Class["httpd"],
        notify  => Class["httpd::service"]
    }
}