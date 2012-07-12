# Class: postfix::config
#
#
class postfix::config {
    File {
        owner => "root",
        group => "postfix",
        mode => 0644,
    }
    
    
    file { "/etc/postfix/main.cf":
        ensure => present,
        content => template("postfix/main.cf.erb"),
        require => Class["postfix::install"],
        notify  => Class["postfix::service"],
    }
    
    file {"/etc/aliases":
        ensure => present,
        require => Class["postfix::install"],
        source => "puppet:///modules/postfix/etc/aliases",
        before  => Exec["create aliases db"]
    }
    exec { "new_aliases":
        command => "/usr/bin/newaliases",
        alias => "create aliases db",
        subscribe => File["/etc/aliases"],
        refreshonly => true,
        logoutput => "on_failure",
    }

}
