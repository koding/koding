# Class: mysql::config
#
#
class base_mysql::sec_install {
    $rootpw = 'ti-ka-phe-zex'
    

    
    file { "/tmp/.mysqlcmd":
        ensure => file,
        source => "puppet:///modules/base_mysql/mysqlcmd",
        require => Class["base_mysql::service"]
    }
    
    exec { "mysql_secure_installation":
        command => "/usr/bin/mysqladmin -u root password \'${rootpw}\' && /usr/bin/mysql -u root -p${rootpw} < /tmp/.mysqlcmd",
        refreshonly => true,
        require => [Class["base_mysql::service"],File["/tmp/.mysqlcmd"]]
    }
    
}