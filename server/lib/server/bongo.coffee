nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mongo, mq, projectRoot, webserver} = KONFIG

mqOptions = extend {}, mq
mqOptions.login = webserver.login  if webserver?.login?
mqOptions.productName = 'koding-webserver'

module.exports = new Bongo {
  mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
  mq: new Broker mqOptions
  resourceName: webserver.queueName
}