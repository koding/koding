nodePath = require 'path'
# configuration
cwd = process.cwd()

module.exports =
  name                  : "sharedhosting"
  pidPath               : "/var/run/node/SharedHosting.pid"
  logFile               : "/var/log/node/SharedHosting.log"
  # port                  : 4566
  amqp                  :
    host                : 'zb.koding.com'
    username            : 'guest'
    password            : 's486auEkPzvUjYfeFTMQ'
    vhost               : 'kite'
  # pusher                :
  #   appId               : 22120
  #   key                 : 'a6f121a130a44c7f5325'
  #   secret              : '9a2f248630abaf977547'
  # requestHandler        :
  #   isEnabled           : no
  apiUri                : 'https://dev-api.koding.com/1.0'
  usersPath             : '/Users/'
  vhostDir              : 'Sites'
  suspendDir            : '/var/www/suspended_vhosts/'
  defaultVhostFiles     : nodePath.join cwd, '..', 'sharedHosting', 'defaultVhostFiles'
  freeUsersGroup        : 'freeusers'
  liteSpeedUser         : 'lsws'
  defaultDomain         : 'koding.com'
  minAllowedUid         : 600 # minumum allowed UID for OS commands
  debugApi              : true
  processBaseDir        : cwd
  cagefsctl             : "/usr/sbin/cagefsctl"
  baseMountDir          : "RemoteDrives"
  usersMountsFile       : ".cagefs/.mounts"
  ftpfs                 :
    curlftpfs           : '/usr/bin/curlftpfs'
    opts                : "connect_timeout=15,direct_io,allow_other"
  sshfs                 :
    sshfscmd            : '/usr/bin/sshfs'
    opts                : 'UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no,password_stdin,intr,allow_other,direct_io'
    optsWithKey         : 'PubkeyAuthentication=yes,PasswordAuthentication=no,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no,intr,allow_other,direct_io'
  lsws                  :
    baseDir             : '/Users'
    controllerPath      : '/opt/lsws/bin/lswsctrl'
    lsMasterConfig      : '/opt/lsws/conf/master_httpd.xml'
    configFilePath      : '/opt/lsws/conf/httpd_config.xml'
    minRestartInterval  : '10000' # 10 sec
  ldap                  :
    ldapUrl             : 'ldap://ldap0.prod.system.aws.koding.com'
    rootUser            : "uid=KAdmin,ou=Special Users,dc=koding,dc=com"
    rootPass            : 'sOg4:L]iM7!_UV-H'
    groupDN             : 'ou=Beta,ou=Groups,dc=koding,dc=com'
    userDN              : 'ou=Beta,ou=People,dc=koding,dc=com'
    freeUID             : 'uid=betaUsersIDs,dc=koding,dc=com' # special record for next free uid, increments each time when create new user
    freeGroup           : 'cn=freeusers,ou=Groups,dc=koding,dc=com'
  FileSharing           :
    baseSharedDir       : '/Shared'
    baseDir             : '/Users'
    setfacl             : '/usr/bin/setfacl'
