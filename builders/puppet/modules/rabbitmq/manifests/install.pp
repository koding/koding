# Class: rabbitmq::install
#
#
class rabbitmq::install {
    
    
    package { "erlang":
        ensure => installed,
    }
    package { "rabbitmq-server":
        ensure => installed,
	require => [Package["erlang"],Yumrepo["koding"]]
    }
}
