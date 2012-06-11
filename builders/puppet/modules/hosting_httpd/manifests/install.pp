# Class: hosting_httpd::install
#
#
class hosting_httpd::install {
    
    package { [ "httpd", "mod_hostinglimits"]:
        ensure => installed,
    }
}
