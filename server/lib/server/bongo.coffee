nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

{mongo, mq, projectRoot, webserver} = require argv.c

mqOptions = extend {}, mq
mqOptions.login = webserver.login  if webserver?.login?

modelsDir = 'workers/social/lib/social/models/'

module.exports = new Bongo {
  mongo
  models: [
    "#{modelsDir}activity/cache.coffee"
  ].map (path)-> nodePath.join projectRoot, path
  mq: new Broker mqOptions
  resourceName: webserver.queueName
}