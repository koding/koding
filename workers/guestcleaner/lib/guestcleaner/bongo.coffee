nodePath    = require 'path'
Bongo       = require 'bongo'
Broker      = require 'broker'
{argv}      = require 'optimist'
{extend}    = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mq, projectRoot, guestCleanerWorker} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"


# mongo += '?auto_reconnect'  if 'string' is typeof mongo

mqOptions = extend {}, mq
mqOptions.login = guestCleanerWorker.login if guestCleanerWorker?.login?

module.exports = new Bongo {
  mongo
  root: projectRoot
  models: [
    'workers/social/lib/social/models'
  ]
  mq: new Broker mqOptions
  resourceName: guestCleanerWorker.queueName
}
 