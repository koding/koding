class hosting_httpd::user {
    user { "apache":
        ensure => present,
        groups => "secure",
        require => [Class["hosting_httpd::install"],Group["secure"]],
    }

}
