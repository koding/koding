# Class: base_mysql::install
#
#
class hosting_mysql::install {
    
    package { "mysql-server":
        ensure => installed,
        notify => Class["hosting_mysql::sec_install"]   
    }
    
}