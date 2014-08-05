process.title = 'koding-socialworker'
require "../../../arrayproto"

log = -> console.log arguments...

{argv} = require 'optimist'

{exec} = require 'child_process'
{extend} = require 'underscore'
{ join: joinPath } = require 'path'

process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack
  process.exit 1

Bongo = require 'bongo'
Broker = require 'broker'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
Object.defineProperty global, 'KONFIG', value: KONFIG
{mq, email, social, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"  if 'string' is typeof KONFIG.mongo

mqOptions = extend {}, mq
mqOptions.login = social.login if social?.login?

broker = new Broker mqOptions



koding = new Bongo {
  verbose     : social.verbose
  root        : __dirname
  mongo       : mongoReplSet or mongo
  models      : './models'
  resourceName: social.queueName
  mq          : broker

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
    JUser.authenticateClient sessionToken, context, (err, account)->
      if err
        console.error "bongo.fetchClient", {err, sessionToken, context}
        koding.emit 'error', err
      else if account instanceof JAccount
        callback {sessionToken, context, connection:delegate:account}
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
app.use express.compress()
app.use express.bodyParser()
helmet.defaults app
app.use cors()

app.post '/xhr', koding.expressify()

app.listen argv.p
