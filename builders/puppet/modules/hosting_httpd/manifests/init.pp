# Class: hosting_httpd
#
#
class hosting_httpd {
    include hosting_httpd::install, hosting_httpd::service,hosting_httpd::config
}
