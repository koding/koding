# Class: rabbitmq::install
#
#
class rabbitmq::install {
    
    
    package { "esl-erlang":
        ensure => installed,
    }
    package { "rabbitmq-server":
        ensure => installed,
    	require => [Package["esl-erlang"],Yumrepo["koding"],Yumrepo["erlang"]]
    }
}
