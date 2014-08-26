nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{projectRoot, webserver, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"

module.exports = koding = new Bongo {
  mongo: mongoReplSet or mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
  fetchClient :(sessionToken, context, callback)->
    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback] unless callback
    context             ?= group: 'koding'
    callback            ?= ->
    JUser.authenticateClient sessionToken, context, (err, account)->
      if err
        console.error err
        return

      if account instanceof JAccount
        callback {sessionToken, context, connection:delegate:account}
      else
        callback { message: "Session error" }
}
