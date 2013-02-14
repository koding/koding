nodePath = require 'path'

module.exports =
  name              : "applications"
  pidPath           : "/var/run/node/Applications.pid"
  logFile           : "/var/log/node/Applications.log"
  amqp              :
    host            : 'web0.beta.system.aws.koding.com'
    login           : 'prod-applications-kite'
    password        : 'Dtxym6fRJXx4GJz'
    heartbeat       : 10
  apiUri            : 'https://dev-api.koding.com/1.0'
  usersPath         : '/Users/'
  vhostDir          : 'Sites'
  defaultDomain     : 'rc.koding.com'
  minAllowedUid     : 600 # minumum allowed UID for OS commands
  debugApi          : true