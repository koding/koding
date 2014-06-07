nodePath    = require 'path'
Bongo       = require 'bongo'
Broker      = require 'broker'
{argv}      = require 'optimist'
{extend}    = require 'underscore'
{ join: joinPath } = require 'path'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{mq, projectRoot, authWorker} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"

mqOptions = extend {}, mq
mqOptions.login = authWorker.login if authWorker?.login?

module.exports = new Bongo {
  mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
  mq: new Broker mqOptions
  resourceName: authWorker.queueName
  # TODO: figure out how to recover when kontrol is down.
  # kite          :
  #   kontrol     : 'ws://localhost:4000'
  #   name        : 'authWorker'
  #   environment : KONFIG.environment
  #   region      : argv.r
  #   version     : KONFIG.version
  #   username    : 'koding'
  #   port        : KONFIG.authWorker.kitePort
  #   kiteKey     : joinPath __dirname, '../../../../kite_home/koding/kite.key'
}