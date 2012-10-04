Bongo = require 'bongo'
Broker = require 'broker'
{argv} = require 'optimist'


{mongo, mq} = require argv.c

module.exports = new Bongo {
  mongo
  root: __dirname
  models: [
    '../workers/social/lib/social/models/session.coffee'
    '../workers/social/lib/social/models/guest.coffee'
  ]
  mq: new Broker mq
  queueName: 'koding-social'
}
