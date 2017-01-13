Bongo      = require 'bongo'
{ extend } = require 'underscore'

KONFIG = require 'koding-config-manager'
{ projectRoot, webserver, mongoReplSet } = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"

options =
  max   : 1000 # max 1K item
  maxAge: 1000 * 60 * 60 # 1 hour

cache = require('lru-cache')(options)

redisClient = require('redis').createClient(
  KONFIG.redis.port
  KONFIG.redis.host
  {}
)

module.exports = koding = new Bongo
  cache       : cache
  redisClient : redisClient
  mongo       : mongoReplSet or mongo
  root        : projectRoot
  models      : 'workers/social/lib/social/models'
  fetchClient : (sessionToken, context, callback) ->

    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback]  unless callback

    callback ?= ->

    JUser.authenticateClient sessionToken, (err, res = {}) ->

      if err
        console.error '[fetchClient]', err
        return callback err

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
