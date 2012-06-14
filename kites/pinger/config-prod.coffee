nodePath = require 'path'
# configuration

module.exports =
  name              : "pinger"
  pidPath           : "/var/run/node/pinger.pid"
  logFile           : "/var/log/node/pinger.log"
  port              : 4565
  pusher            :
    appId           : 18240
    key             : 'a19c8bf6d2cad6c7a006'
    secret          : '51f7913fbb446767a9fb'
  apiUri            : 'https://api.koding.com/1.0'
