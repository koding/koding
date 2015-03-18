Bongo       = require 'bongo'
{argv}      = require 'optimist'
{extend}    = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mongo, projectRoot, emailConfirmationCheckerWorker : config} = KONFIG

mongo += '?auto_reconnect'  if 'string' is typeof mongo

mongo = "mongodb://#{mongo}?auto_reconnect"  if 'string' is typeof mongo
module.exports = new Bongo {
  mongo
  root: projectRoot
  models: [
    'workers/social/lib/social/models'
  ]
  resourceName: config.queueName
}
