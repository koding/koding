nodePath = require 'path'

module.exports =
  name              : "applications"
  pidPath           : "/var/run/node/Applications.pid"
  logFile           : "/var/log/node/Applications.log"
  amqp              :
    host            : 'zb.koding.com'
    username        : 'guest'
    password        : 's486auEkPzvUjYfeFTMQ'
    vhost           : 'kite'
  apiUri            : 'https://dev-api.koding.com/1.0'
  usersPath         : '/Users/'
  vhostDir          : 'Sites'
  defaultDomain     : 'koding.com'
  minAllowedUid     : 600 # minumum allowed UID for OS commands
  debugApi          : true
