class mail_relay::clamav_service {
    service { "clamsmtp-clamd":
       ensure => running,
       hasstatus => true,
       hasrestart => true,
       enable => true,
       require => Class["mail_relay::config"],
     }
    service { "clamsmtpd":
       ensure => running,
       hasstatus => true,
       hasrestart => true,
       enable => true,
       require => Class["mail_relay::config"],
     }

}
