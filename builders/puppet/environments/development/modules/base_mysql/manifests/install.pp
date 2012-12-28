# Class: base_mysql::install
#
#
class base_mysql::install {
    
    package { "mysql-server":
        ensure => installed,
        notify => Class["base_mysql::sec_install"]   
    }
    
}