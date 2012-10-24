# Class: mysql::config
#
#
class hosting_mysql::sec_install {
    $rootpw = 'ti-ka-phe-zex'
    

    
    file { "/tmp/.mysqlcmd":
        ensure => file,
        source => "puppet:///modules/hosting_mysql/mysqlcmd",
        require => Class["hosting_mysql::service"]
    }
    
    exec { "mysql_secure_installation":
        command => "/usr/bin/mysqladmin -u root password \'${rootpw}\' && /usr/bin/mysql -u root -p${rootpw} < /tmp/.mysqlcmd",
        refreshonly => true,
        unless => "/usr/bin/mysqladmin -uroot -p$rootpw status",
        require => [Class["hosting_mysql::service"],File["/tmp/.mysqlcmd"]]
    }
    
}
