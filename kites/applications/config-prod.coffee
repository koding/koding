nodePath = require 'path'

module.exports =
  name              : "applications"
  pidPath           : "/var/run/node/Applications.pid"
  logFile           : "/var/log/node/Applications.log"
  amqp              :
    host            : 'web0.beta.system.aws.koding.com'
    username        : 'prod-applications-kite'
    password        : 'Dtxym6fRJXx4GJz'
    vhost           : '/'
  apiUri            : 'https://api.koding.com/1.0'
  usersPath         : '/Users/'
  vhostDir          : 'Sites'
  defaultDomain     : 'koding.com' # We use this domain in createVHost method
  minAllowedUid     : 600 # minumum allowed UID for OS commands
  debugApi          : true
