# Class: base_mysql::config
#
#
class hosting_mysql::config {
 if $master {
    file { "/etc/my.cnf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        content => template("hosting_mysql/master.my.cnf.erb"),
        require => Class["hosting_mysql::install"],
        notify  => Class["hosting_mysql::service"],
    }
 } else {
     file { "/etc/my.cnf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        content => template("hosting_mysql/slave.my.cnf.erb"),
        require => Class["hosting_mysql::install"],
        notify  => Class["hosting_mysql::service"],
    }
   
 }
}
