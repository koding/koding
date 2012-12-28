nodePath = require 'path'
# configuration

module.exports =
  name       : "dummyamqpkite"
  pidPath    : "/var/run/node/pinger.pid"
  logFile    : "/var/log/node/pinger.log"
  amqp       :
    host     : 'localhost'
    username : 'guest'
    password : 'guest'

