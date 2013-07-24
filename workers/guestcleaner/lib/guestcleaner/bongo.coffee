nodePath    = require 'path'
Bongo       = require 'bongo'
Broker      = require 'broker'
{argv}      = require 'optimist'
{extend}    = require 'underscore'

{mongo, mq, projectRoot, guestCleanerWorker} = require('koding-config-manager').load("main.#{argv.c}")
mongo += '?auto_reconnect'
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
