log4js  = require 'log4js'
logger  = log4js.getLogger('log')

log4js.configure {
  appenders: [
    { type: 'console' }
    { type: 'file', filename: 'logs/log.log', category: 'log' }
    { type: "log4js-node-syslog", tag : "log", facility: "local0", hostname: "localhost", port: 514 }
  ],
  replaceConsole: true
}

{argv} = require 'optimist'

{exec} = require 'child_process'
{extend} = require 'underscore'

process.on 'uncaughtException', (err)->
  console.log err, err?.stack
  process.exit 1

Bongo = require 'bongo'
Broker = require 'broker'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
Object.defineProperty global, 'KONFIG', value: KONFIG
{mq, email, log, mongoReplSet} = KONFIG

mongo = "mongodb://#{KONFIG.mongo}?auto_reconnect"  if 'string' is typeof KONFIG.mongo

mqOptions = extend {}, mq
mqOptions.login = log.login if log.login?

broker = new Broker mqOptions

processMonitor = (require 'processes-monitor').start
  name : "Log Worker #{process.pid}"
  stats_id: "worker.log." + process.pid
  interval : 30000
  limit_hard  :
    memory   : 300
    callback : (name,msg,details)->
      console.log "[#{JSON.stringify(new Date())}][LOG WORKER #{name}] Using excessive memory, exiting."
      process.exit()
  die :
    after: "non-overlapping, random, 3 digits prime-number of minutes"
    middleware : (name,callback) -> koding.disconnect callback
    middlewareTimeout : 15000

require_koding_model = require "./require_koding_model"

koding = new Bongo {
  verbose     : log.verbose
  root        : __dirname
  mongo       : mongoReplSet or mongo
  models      : './models'
  resourceName: log.queueName
  mq          : broker
  fetchClient :(sessionToken, context, callback)->
    JUser    = require_koding_model "user/index"
    JAccount = require_koding_model "account"

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

console.info "Koding Log Worker #{process.pid} has started."

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
