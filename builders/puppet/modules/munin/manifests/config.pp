# Class: munin::config
#
#
class munin::config {
    file { "/etc/munin/munin-node.conf":
        ensure => present,
        owner => "root",
        group => "root",
        mode => 0644,
        require => Class["munin::install"],
        notify  => Class["munin::service"],
        content => template("munin/munin-node.conf.erb"),
    }

}