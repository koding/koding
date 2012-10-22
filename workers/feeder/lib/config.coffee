nodePath = require 'path'
{argv} = require 'optimist'

if argv.c?
  config = require argv.c
  config.queueName = config.feeder.queueName
  config.exchangePrefix = config.feeder.exchangePrefix

  module.exports = config
else
  mongo = "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"

  module.exports =
    mongo         : mongo
    queueName     : "koding-feeder"
    exchangePrefix: "followable-"
    mq            :
      host        : 'localhost'
      login       : 'guest'
      password    : 'guest'
      pidFile     : '/var/run/broker.pid'
