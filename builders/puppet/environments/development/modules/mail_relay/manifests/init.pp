class mail_relay {
  include mail_relay::install, mail_relay::config, mail_relay::postfix_service, mail_relay::dkim_service
  include mail_relay::clamav_service
}
