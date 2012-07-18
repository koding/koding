# Class: static_httpd
#
#
class static_httpd {
    include static_httpd::install, static_httpd::config, static_httpd::service
}
