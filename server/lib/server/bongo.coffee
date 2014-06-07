nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'
{ join: joinPath } = require 'path'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mq, projectRoot, webserver, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"

mqOptions = extend {}, mq
mqOptions.login = webserver.login  if webserver?.login?
mqOptions.productName = 'koding-webserver'

module.exports = new Bongo {
  mongo: mongoReplSet or mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
  mq: new Broker mqOptions
  resourceName: webserver.queueName
  kite          :
    kontrol     : 'ws://localhost:4000'
    name        : 'webserver'
    environment : KONFIG.environment
    region      : argv.r
    version     : KONFIG.version
    username    : 'koding'
    port        : KONFIG.webserver.kitePort
    kiteKey     : joinPath __dirname, '../../../kite_home/koding/kite.key'

    fetchClient: (name, context, callback) ->
      { JAccount } = koding.models
      [callback, context] = [context, callback] unless callback
      context   ?= group: 'koding'
      callback  ?= ->
      JAccount.one 'profile.nickname': name, (err, account) ->
        return callback err  if err?

        if account instanceof JAccount
          callback null, { context, connection:delegate:account }
}