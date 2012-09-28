# Class: hosting_mysql
#
#
class hosting_mysql {

  include hosting_mysql::install,hosting_mysql::service,hosting_mysql::config,hosting_mysql::sec_install
  
  
}