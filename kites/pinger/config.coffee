nodePath = require 'path'
# configuration

module.exports =
  name              : "pinger"
  pidPath           : "/var/run/node/pinger.pid"
  logFile           : "/var/log/node/pinger.log"
  port              : 4565