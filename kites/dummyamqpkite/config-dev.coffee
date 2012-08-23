nodePath = require 'path'
# configuration

module.exports =
  name       : "dummyamqpkite"
  pidPath    : "/var/run/node/pinger.pid"
  logFile    : "/var/log/node/pinger.log"
  amqp       :
    host     : 'web0.beta.system.aws.koding.com'
    username : 'guest'
    password : 'x1srTA7!%Vb}$n|S'

