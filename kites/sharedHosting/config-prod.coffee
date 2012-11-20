nodePath = require 'path'
# configuration

module.exports =
  name                  : "sharedhosting"
  pidPath               : "/var/run/node/SharedHosting.pid"
  logFile               : "/var/log/node/SharedHosting.log"
  amqp                  :
    host                : 'web0.beta.system.aws.koding.com'
    username            : 'prod-sharedhosting-kite'
    password            : 'Dtxym6fRJXx4GJz'
    vhost               : '/'
  apiUri                : 'https://api.koding.com/1.0'
  usersPath             : '/Users/'
  vhostDir              : 'Sites'
  suspendDir            : '/var/www/suspended_vhosts/'
  defaultVhostFiles     : nodePath.join process.cwd(), '..', 'sharedHosting', 'defaultVhostFiles'
  freeUsersGroup        : 'freeusers'
  liteSpeedUser         : 'lsws'
  defaultDomain         : 'koding.com' # We use this domain in createVHost method
  minAllowedUid         : 600 # minumum allowed UID for OS commands
  debugApi              : true
  processBaseDir        : process.cwd()
  cagefsctl             : "/usr/sbin/cagefsctl"
  baseMountDir          : 'RemoteDrive'
  ftpfs                 :
    curlftpfs           : '/usr/bin/curlftpfs'
    opts                : "connect_timeout=15,direct_io,allow_other"
  sshfs                 :
    sshfscmd            : '/usr/bin/sshfs'
    opts                : "ssh_command='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no',password_stdin,intr,allow_other,direct_io"
    optsWithKey         : "ssh_command='ssh -o PubkeyAuthentication -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/koding.pem',intr,allow_other,direct_io"
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