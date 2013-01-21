# Class: postfix::config
#
#
class mail_relay::config {
    File {
        owner => "root",
        group => "postfix",
        mode => 0644,
    }
    
    
    file { "/etc/postfix/main.cf":
        ensure => present,
        content => template("mail_relay/main.cf.erb"),
        require => Class["mail_relay::install"],
        notify  => Class["mail_relay::postfix_service"],
    }
     file {"/etc/postfix/master.cf":
        ensure => present,
        source => "puppet:///modules/mail_relay/etc/postfix/master.cf",
        require => Class["mail_relay::install"],
        notify  => Class["mail_relay::postfix_service"],
    }
   
    file {"/etc/aliases":
        ensure => present,
        require => Class["mail_relay::install"],
        source => "puppet:///modules/mail_relay/etc/aliases",
        before  => Exec["create aliases db"]
    }
    exec { "new_aliases":
        command => "/usr/bin/newaliases",
        alias => "create aliases db",
        subscribe => File["/etc/aliases"],
        refreshonly => true,
        logoutput => "on_failure",
    }
    
    # opendkim configuration
    
    file { "/etc/sysconfig/opendkim":
        ensure => file,
        owner => root,
        group => root,
        source => "puppet:///modules/mail_relay/etc/sysconfig/opendkim",
        require => Class['mail_relay::install'],
        notify => Class['mail_relay::dkim_service']
    }
    file { "/etc/opendkim.conf":
        ensure => file,
        owner => root,
        group => root,
        source => "puppet:///modules/mail_relay/etc/opendkim.conf",
        require => Class['mail_relay::install'],
        notify => Class['mail_relay::dkim_service']
    }
    
    file { "/etc/opendkim/keys/mail.private":
        ensure => file,
        owner => opendkim,
        group => root,
        mode => 0600,
        source => "puppet:///modules/mail_relay/etc/opendkim/keys/mail.private",
        require => Class['mail_relay::install'],
        notify => Class['mail_relay::dkim_service']
    }

    file { "/etc/opendkim/TrustedHosts":
          ensure => file,
          owner => opendkim,
          group => root,
          mode => 0600,
          source => "puppet:///modules/mail_relay/etc/opendkim/TrustedHosts",
          require => Class['mail_relay::install'],
          notify => Class['mail_relay::dkim_service']
    }

    file { "/etc/clamd.d/clamsmtp.conf":
          ensure => file,
          owner => opendkim,
          group => root,
          mode => 0600,
          source => "puppet:///modules/mail_relay/etc/clamd.d/clamsmtp.conf",
          require => Class['mail_relay::install'],
          notify => Class['mail_relay::clamav_service']
    }

    file { "/etc/clamsmtpd.conf":
          ensure => file,
          owner => opendkim,
          group => root,
          mode => 0600,
          source => "puppet:///modules/mail_relay/etc/clamsmtpd.conf",
          require => Class['mail_relay::install'],
          notify => Class['mail_relay::clamav_service']
    }

   cron { freshclam:
        command => "/usr/bin/freshclam --quiet",
        user    => root,
        hour    => 1,
        minute  => 0,
        require => Class['mail_relay::install']
   }


}
