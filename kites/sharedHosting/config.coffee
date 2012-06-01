nodePath = require 'path'
# configuration

module.exports =
  name              : "sharedhosting"
  pidPath           : "/var/run/node/SharedHosting.pid"
  logFile           : "/var/log/node/SharedHosting.log"
  port              : 4566
  usersPath         : '/Users/'
  vhostDir          : 'Sites'
  suspendDir        : '/var/www/suspended_vhosts/'
  defaultVhostFiles : nodePath.join process.cwd(),"defaultVhostFiles"
  freeUsersGroup    : 'freeusers'
  liteSpeedUser     : 'lsws'
  defaultDomain     : 'beta.koding.com'
  minAllowedUid     : 600 # minumum allowed UID for OS commands
  debugApi          : true
  processBaseDir    : process.cwd()
  lsws              :
    baseDir            : '/Users'
    controllerPath     : '/opt/lsws/bin/lswsctrl'
    lsMasterConfig     : '/opt/lsws/conf/master_httpd.xml'
    configFilePath     : '/opt/lsws/conf/httpd_config.xml'
    minRestartInterval : '10000' # 10 sec
  ldap              :
    ldapUrl  : 'ldap://ldap0.prod.system.aws.koding.com'
    rootUser : "cn=Directory Manager"  
    rootPass : '35acb84L##'
    groupDN  : 'ou=Beta,ou=Groups,dc=koding,dc=com'
    userDN   : 'ou=Beta,ou=People,dc=koding,dc=com'
    freeUID  : 'uid=betaUsersIDs,dc=koding,dc=com' # special record for next free uid, increments each time when create new user
    freeGroup: 'cn=freeusers,ou=Groups,dc=koding,dc=com'