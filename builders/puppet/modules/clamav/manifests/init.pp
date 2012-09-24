class clamav {
  include clamav::install
  include clamav::config
  include clamav::service
  include clamav::crontabs
}
