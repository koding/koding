{argv} = require 'optimist'

{webserver, mongo, mq, projectRoot, kites, basicAuth} = require argv.c

webPort = argv.p ? webserver.port

{extend} = require 'underscore'
express = require 'express'
Broker = require 'broker'
Bongo = require 'bongo'
gzippo = require 'gzippo'
fs = require 'fs'
hat = require 'hat'

app = express.createServer()

app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session {"secret":"foo"}
app.use gzippo.staticGzip "#{projectRoot}/website/"
app.use (req, res, next)->
  res.removeHeader("X-Powered-By")
  next()

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException',(err)->
  console.log 'there was an uncaught exception'
  console.error err
  console.trace()

mqOptions = extend {}, mq
mqOptions.login = webserver.login if webserver?.login?

koding = new Bongo {
  mongo
  root: __dirname
  models: [
    '../workers/social/lib/social/models/session.coffee'
    '../workers/social/lib/social/models/account.coffee'
    '../workers/social/lib/social/models/guest.coffee'
  ]
  mq: new Broker mqOptions
  queueName: 'koding-social'
}

kiteBroker =\
  if kites?.vhost?
    new Broker extend {}, mq, vhost: kites.vhost
  else
    koding.mq

koding.mq.connection.on 'ready', ->
  console.log 'message broker is ready'

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

app.get '/auth', (req, res)->
  crypto = require 'crypto'
  {JSession} = koding.models
  channel = req.query?.channel
  return res.send 'user error', 400 unless channel?
  clientId = req.cookies.clientid
  JSession.fetchSession clientId, (err, session)->
    res.cookie 'clientId', session.clientId if session? and clientId isnt session?.clientId
    if err
      authenticationFailed(res, err)
    else
      [priv, type, pubName] = channel.split '-'
      if /^bongo\./.test type
        privName = 'secret-bongo-'+hat()+'.private'
        koding.mq.funnel privName, koding.queueName
        res.send privName
      else unless session?
        authenticationFailed(res)
      else if type is 'kite'
        {username} = session
        cipher = crypto.createCipher('aes-256-cbc', '2bB0y1u~64=d|CS')
        cipher.update(
          ''+pubName+req.cookies.clientid+Date.now()+Math.random()
        )
        privName = ['secret', 'kite', cipher.final('hex')+".#{username}"].join '-'
        privName += '.private'

        bindKiteQueue = (binding, callback) ->
          kiteBroker.bindQueue(
            privName, privName, binding,
            {queueDurable:no, queueExclusive:no},
            callback
            )

        bindKiteQueue "client-message", (kiteCmQueue1, exchangeName)->
          kiteCmQueue1.close() # this will get opened back up?
          bindKiteQueue "disconnected", (kiteCmQueue2, exchangeName) ->
            kiteBroker.emit(channel, 'join', {user: username, queue: privName})

            kiteBroker.connection.on 'error', console.log
            kiteBroker.createQueue '', (dcQueue)->
              dcQueue.bind exchangeName, 'disconnected'
              dcQueue.subscribe ->
                dcQueue.destroy()#.addCallback -> dcQueue.close()
                setTimeout ->
                  kiteCmQueue2.destroy()#.addCallback -> kiteCmQueue.close()
                , kites?.disconnectTimeout ? 5000
            return res.send privName

app.get "/", (req, res)->
  if frag = req.query._escaped_fragment_?
    res.send 'this is crawlable content'
  else
    # log.info "serving index.html"
    res.header 'Content-type', 'text/html'
    fs.readFile "#{projectRoot}/website/index.html", (err, data) ->
      throw err if err
      res.send data

app.get "/status/:data",(req,res)->
  # req.params.data

  # connection.exchange 'public-status',{autoDelete:no},(exchange)->
  # exchange.publish 'exit','sharedhosting is dead'
  # exchange.close()
  koding.mq.emit 'public-status','exit',req.params.data
  res.send "alright."

app.get "/api/user/:username/flags/:flag", (req, res)->
  {username, flag} = req.params
  {JAccount}       = koding.models

  JAccount.one "profile.nickname" : username, (err, account)->
    if err or not account
      state = false
    else
      state = account.checkFlag('super-admin') or account.checkFlag(flag)
    res.end "#{state}"

app.get '*', (req,res)->
  res.header 'Location', '/#!'+req.url
  res.send 302

app.listen webPort

console.log 'Koding Webserver running ', "http://localhost:#{webPort}"
