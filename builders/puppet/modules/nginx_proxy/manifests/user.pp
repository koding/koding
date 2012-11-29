class nginx_proxy::user {
    user { "nginx":
        ensure => present,
        groups => "secure",
        require => [Class["nginx_proxy::install"],Group["secure"]],
    }

}
