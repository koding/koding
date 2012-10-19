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
