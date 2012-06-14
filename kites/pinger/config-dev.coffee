nodePath = require 'path'
# configuration

module.exports =
  name              : "pinger"
  pidPath           : "/var/run/node/pinger.pid"
  logFile           : "/var/log/node/pinger.log"
  port              : 4565
  pusher            :
    appId           : 22120
    key             : 'a6f121a130a44c7f5325'
    secret          : '9a2f248630abaf977547'
  apiUri            : 'https://dev-api.koding.com/1.0'
