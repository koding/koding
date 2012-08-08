# Class: httpd
#
#
class httpd {
    include httpd::install, httpd::service
}