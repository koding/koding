class hosting_httpd::user {
    group { "secure":
      ensure => present,
      gid => 66,
      require => Class["hosting_httpd::install"],
  }

    user { "apache":
        ensure => present,
        groups => "secure",
        require => [Class["hosting_httpd::install"],Group["secure"]],
    }

}
