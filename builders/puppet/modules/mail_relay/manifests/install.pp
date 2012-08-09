# Class: postfix:install
#
#
class mail_relay::install {
    package { ["postfix","mailx","opendkim"]:
        ensure => present,
    }

    package { "sendmail":
        ensure => absent,
        require => Package["postfix","mailx","opendkim"]
    }

}
