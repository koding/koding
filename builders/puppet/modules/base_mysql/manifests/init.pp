define base_mysql::createdb($rootpw, $user, $password ) {

  include base_mysql::install,base_mysql::service,base_mysql::config,base_mysql::sec_install
  
  exec { "create-${name}-db":
    unless => "/usr/bin/mysql -u${user} -p${password} ${name}",
    command => "/usr/bin/mysql -uroot -p$rootpw -e \"create database ${name}; grant all on ${name}.* to ${user}@localhost identified by '$password'; FLUSH PRIVILEGES;\"",
    require => [Class["base_mysql::service"],Class["base_mysql::sec_install"]]
  }
  
}