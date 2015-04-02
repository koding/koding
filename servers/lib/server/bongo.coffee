nodePath = require 'path'
Bongo    = require 'bongo'
Broker   = require 'broker'
{argv}   = require 'optimist'
{extend} = require 'underscore'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{projectRoot, webserver, mongoReplSet, mq, socialapi} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"

mqConfig = {host: mq.host, port: mq.port, login: mq.login, password: mq.password, vhost: mq.vhost}

# TODO exchange version must be injected here, when we have that support
mqConfig.exchangeName = "#{socialapi.eventExchangeName}:0"

mqOptions = extend {}, mq
broker = new Broker mqOptions

module.exports = koding = new Bongo

  mq          : broker
  mqConfig    : mqConfig
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
