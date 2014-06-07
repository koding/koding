Bongo       = require 'bongo'
Broker      = require 'broker'
{argv}      = require 'optimist'
{extend}    = require 'underscore'
{ join: joinPath } = require 'path'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mongo, mq, projectRoot, emailConfirmationCheckerWorker : config} = KONFIG

mongo += '?auto_reconnect'  if 'string' is typeof mongo

mqOptions = extend {}, mq
mqOptions.login = config.login if config?.login?

mongo = "mongodb://#{mongo}?auto_reconnect"  if 'string' is typeof mongo
module.exports = new Bongo {
  mongo
  root: projectRoot
  models: [
    'workers/social/lib/social/models'
  ]
  mq: new Broker mqOptions
  resourceName: config.queueName
  kite          :
    kontrol     : 'ws://localhost:4000'
    name        : 'emailConfirmationChecker'
    environment : KONFIG.environment
    region      : argv.r
    version     : KONFIG.version
    username    : 'koding'
    port        : KONFIG.emailConfirmationCheckerWorker.kitePort
    kiteKey     : joinPath __dirname, '../../../../kite_home/koding/kite.key'
}
