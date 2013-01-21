class mail_relay::dkim_service {
    service { "opendkim":
       ensure => running,
       hasstatus => true,
       hasrestart => true,
       enable => true,
       require => Class["mail_relay::config"],
     }
}