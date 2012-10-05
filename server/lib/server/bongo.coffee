nodePath = require 'path'
Bongo = require 'bongo'
Broker = require 'broker'
{argv} = require 'optimist'

{mongo, mq, projectRoot} = require argv.c

module.exports = new Bongo {
  mongo
  models: [
    'workers/social/lib/social/models/session.coffee'
    'workers/social/lib/social/models/guest.coffee'
  ].map (path)-> nodePath.join projectRoot, path
  mq: new Broker mq
  queueName: 'koding-social'
}
