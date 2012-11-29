class hosting_clamav {
  include hosting_clamav::install
  include hosting_clamav::config
  include hosting_clamav::service
  include hosting_clamav::cron
}
