# Class: hosting_httpd
#
#
class hosting_httpd {
    include hosting_httpd::install
    include hosting_httpd::service
    include hosting_httpd::config
    include hosting_httpd::user
}
