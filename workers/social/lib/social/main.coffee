process.title = 'koding-socialworker'

log = -> console.log arguments...

{argv} = require 'optimist'

{exec} = require 'child_process'
{extend} = require 'underscore'
{ join: joinPath } = require 'path'

usertracker = require('../../../usertracker')

process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack
  process.exit 1

Bongo = require 'bongo'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
Object.defineProperty global, 'KONFIG', value: KONFIG
{mq, email, social, mongoReplSet, socialapi} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"  if 'string' is typeof KONFIG.mongo

broker = new Broker mqOptions

mqConfig = {host: mq.host, port: mq.port, login: mq.login, password: mq.password, vhost: mq.vhost}
mqConfig.exchangeName = socialapi.eventExchangeName

mongo = "mongodb://#{KONFIG.mongo}"  if 'string' is typeof KONFIG.mongo


koding = new Bongo {
  verbose     : social.verbose
  root        : __dirname
  mongo       : mongoReplSet or mongo
  models      : './models'
  resourceName: social.queueName
  mqConfig    : mqConfig

  kite          :
    name        : 'social'
    environment : argv.environment or KONFIG.environment
    region      : argv.region
    version     : KONFIG.version
    username    : 'koding'
    port        : argv['kite-port']
    prefix      : 'social'
    kiteKey     : argv['kite-key']

    fetchClient: (name, context, callback) ->
      { JAccount } = koding.models
      [callback, context] = [context, callback] unless callback
      context   ?= group: 'koding'
      callback  ?= ->
      JAccount.one 'profile.nickname': name, (err, account) ->
        return callback err  if err?

        if account instanceof JAccount
          callback null, { context, connection:delegate:account }

  fetchClient :(sessionToken, context, callback)->
    { JUser, JAccount } = koding.models
    [callback, context] = [context, callback] unless callback
    context             ?= group: 'koding'
    callback            ?= ->
    JUser.authenticateClient sessionToken, context, (err, res = {})->

      { account, session } = res

      if err
        console.error "bongo.fetchClient", {err, sessionToken, context}
        koding.emit 'error', err

      else if account instanceof JAccount

        usertracker.track account.profile.nickname

        { clientIP } = session
        callback {
          sessionToken, context, clientIP,
          connection:delegate:account
        }

      else
        console.error "this is not a proper account", {sessionToken}
        console.error "constructor is JAccount", JAccount is account.constructor
}

koding.on 'authenticateUser', (client, callback)->
  {delegate} = client.connection
  callback delegate

koding.on "errFirstDetected", (err)-> console.error err

koding.connect ->
  (require './init').init koding

  # create default roles for groups
  JGroupRole = require './models/group/role'

  JGroupRole.createDefaultRoles (err)->
    if err then console.log err.message
    else console.log "Default group roles created!"

  if KONFIG.misc?.claimGlobalNamesForUsers
    require('./models/account').reserveNames console.log

  if KONFIG.misc?.updateAllSlugs
    require('./traits/slugifiable').updateSlugsByBatch 100, [
      require './models/tag'
      require './models/app'
    ]

console.info "Koding Social Worker #{process.pid} has started."

express = require 'express'
cors = require 'cors'
helmet = require 'helmet'
app = express()

do ->
  usertracker.start()

  compression = require 'compression'
  bodyParser = require 'body-parser'

  app.use compression()
  app.use bodyParser.json()
  helmet.defaults app
  app.use cors()

  app.post '/xhr', koding.expressify()
  app.get '/xhr',(req,res)->
    res.send "Socialworker is OK"

  app.get '/version',(req,res)->
    res.send "#{KONFIG.version}"

  app.get '/healthCheck',(req,res)->
    res.send "Socialworker is running with version: #{KONFIG.version}"

  app.listen argv.p
