class hosting_httpd::user {
    group { "secure":
        ensure => present,
        gid => 66,
        members => "apache",
        require => Class["hosting_httpd::install"],
    }

        
}
