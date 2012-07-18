# Class: postfix:install
#
#
class postfix::install {
   package { ["postfix","mailx"]:
        ensure => present,
    }
    package { "sendmail":
    	ensure => absent,
    	require => Package["postfix","mailx"]
    }
} 
