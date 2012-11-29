# Class: motd
#
#
class motd {
    File {
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    
    file { "/etc/motd":
        ensure => present,
        content => template("motd/motd.erb"),
    }
}