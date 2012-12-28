# Class: hosting_httpd::install
#
#
class hosting_httpd::install {
    
    package { [ "httpd", "mod_hostinglimits", "mod_fcgid"]:
        ensure => installed,
        require => Class["yumrepos::koding"],
    }
}
