{argv} = require 'optimist'

{webPort, mongo, amqp} = require argv.c
webPort = argv.p if argv.p?

projectRoot = require('path').join(__dirname, '/..')

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

process.on 'uncaughtException',(err)->
  console.error err
  console.trace()

koding = new Bongo {
  mongo
  root: __dirname
  models: [
    '../workers/social/lib/social/models/session.coffee'
    '../workers/social/lib/social/models/guest.coffee'
  ]
  mq: new Broker amqp
  queueName: 'koding-social'
}

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403
      
app.get '/auth', (req, res)->
  crypto = require 'crypto'
  {JSession} = koding.models
  channel = req.query?.channel
  return res.send 'user error', 400 unless channel?
  clientId = req.cookies.clientid
  JSession.fetchSession clientId, (err, session)->
    res.cookie 'clientId', session.clientId if clientId isnt session.clientId
    if err
      authenticationFailed(res, err)
    else
      [priv, type, pubName] = channel.split '-'
      if /^bongo\./.test type
        privName = 'secret-bongo-'+hat()+'.private'
        koding.mq.funnel privName, koding.queueName
        koding.mq.on privName, 'disconnect', console.log
        res.send privName 
      else unless session?
        authenticationFailed(res)
      else
        {username} = session
        cipher = crypto.createCipher('aes-256-cbc', '2bB0y1u~64=d|CS')
        cipher.update(
          ''+pubName+req.cookies.clientid+Date.now()+Math.random()
        )
        privName = ['secret', type, cipher.final('hex')+".#{username}"].join '-'
        privName += '.private'
        koding.mq.emit(channel, 'join', privName)
        return res.send privName

app.get "/", (req, res)->
  if frag = req.query._escaped_fragment_?
    res.send 'this is crawlable content '
  else
    # log.info "serving index.html"
    res.header 'Content-type', 'text/html'
    fs.readFile "#{projectRoot}/website_nonstatic/index.html", (err, data) ->
      throw err if err
      res.send data

app.get '*', (req,res)->
  res.header 'Location', '/#!'+req.url
  res.send 302

app.listen webPort

console.log 'Koding Webserver running ', "http://localhost:#{webPort}"
