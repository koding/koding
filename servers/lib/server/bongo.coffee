nodePath = require 'path'
Bongo      = require 'bongo'
Broker     = require 'broker'
{ argv }   = require 'optimist'
{ extend } = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{ projectRoot, webserver, mongoReplSet } = KONFIG

redisClient = require('redis').createClient(
  KONFIG.monitoringRedis.split(':')[1]
  KONFIG.monitoringRedis.split(':')[0]
  {}
)

mongo = "mongodb://#{KONFIG.mongo}"

module.exports = koding = new Bongo

  mongo       : mongoReplSet or mongo
  root        : projectRoot
  models      : 'workers/social/lib/social/models'
  redisClient : redisClient
  fetchClient : (sessionToken, context, callback) ->

    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback]  unless callback

    callback ?= ->

    JUser.authenticateClient sessionToken, (err, res = {}) ->

      return console.error err  if err

      { account, session } = res
      context ?= { group: session?.groupName ? 'koding' }

      if account instanceof JAccount

        { clientIP, clientId } = session

        # If requested sessionToken is not valid JUser::authenticateClient
        # creates and returns a new session token which then we need to
        # override sessionToken here in case of token changes ~ GG
        sessionToken = clientId

        callback {
          sessionToken, context, clientIP
          connection: { delegate: account }
        }

      else

        callback { message: 'Session error' }
