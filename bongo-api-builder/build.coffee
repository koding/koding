Bongo = require 'bongo'
Broker = require 'broker'
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

require 'colors'

broker = new Broker KONFIG.mq

koding = new Bongo
  root        : __dirname
  mongo       : KONFIG.mongo
  models      : '../workers/social/lib/social/models'
  resourceName: 'bongo-api-builder'
  mq          : broker
  fetchClient : (sessionToken, context, callback) ->
    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback] unless callback
    context             ?= group: 'koding'
    callback            ?= ->
    JUser.authenticateClient sessionToken, context, (err, account) ->
      if err
        koding.emit 'error', err
      else if account instanceof JAccount
        callback {sessionToken, context, connection:delegate:account}
      else
        console.log "this is not a proper account".red, { account }
        koding.emit 'error', message: 'this is not a proper account'

koding.describeApi (api)->
  source = "var REMOTE_API = #{ JSON.stringify api };"
  require('fs').writeFileSync argv.o, source, 'utf-8'
  process.exit()