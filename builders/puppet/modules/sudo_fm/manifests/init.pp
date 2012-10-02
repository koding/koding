class sudo_fm {
    package { sudo:
         ensure => present,
    }

    file { "/etc/sudoers":
        owner => "root",
        group => "root",
        mode => 0440,
        source => "puppet:///modules/sudo_fm/etc/sudoers",
        require => Package["sudo"],
   } 
}
