#
#
class rsyslog {
    include rsyslog::install
    include rsyslog::service
    include rsyslog::config
}
