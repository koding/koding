nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{projectRoot, webserver, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"

module.exports = koding = new Bongo

  mongo       : mongoReplSet or mongo
  root        : projectRoot
  models      : 'workers/social/lib/social/models'
  fetchClient : (sessionToken, context, callback)->

    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback] unless callback
    context             ?= group: 'koding'
    callback            ?= ->

    JUser.authenticateClient sessionToken, context, (err, res = {})->

      return console.error err  if err

      { account, session } = res

      if account instanceof JAccount

        { clientIP, clientId } = session

        # If requested sessionToken is not valid JUser::authenticateClient
        # creates and returns a new session token which then we need to
        # override sessionToken here in case of token changes ~ GG
        sessionToken = clientId

        callback {
          sessionToken, context, clientIP
          connection: delegate: account
        }

      else

        callback { message: "Session error" }
