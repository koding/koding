nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

{mongo, mq, projectRoot} = require argv.c

mqOptions = extend {}, mq
mqOptions.login = webserver.login if webserver?.login?

module.exports = new Bongo {
  mongo
  models: [
    'workers/social/lib/social/models/session.coffee'
    'workers/social/lib/social/models/account.coffee'
    'workers/social/lib/social/models/guest.coffee'
    'workers/social/lib/social/models/activity/cache.coffee'
  ].map (path)-> nodePath.join projectRoot, path
  mq: new Broker mqOptions
  queueName: 'koding-social'
}