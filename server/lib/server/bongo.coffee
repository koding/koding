nodePath = require 'path'
Bongo = require 'bongo'
Broker = require 'broker'
{argv} = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mongo, mq, projectRoot, webserver} = KONFIG

mqOptions = extend {}, mq
mqOptions.login = webserver.login  if webserver?.login?

modelsDir = 'workers/social/lib/social/models/'

module.exports = new Bongo {
  mongo
  models: [
    "#{modelsDir}session.coffee"
    "#{modelsDir}account.coffee"
    "#{modelsDir}guest.coffee"
  ].map (path)-> nodePath.join projectRoot, path
  mq: new Broker mqOptions
  resourceName: webserver.queueName
}