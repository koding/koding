{argv} = require 'optimist'

console.log argv

KONFIG = require argv.c?.trim()
{webserver, mongo, mq, projectRoot, kites, uploads, basicAuth} = KONFIG

webPort = argv.p ? webserver.port

# processMonitor = (require 'processes-monitor').start
#   name : "webServer on port #{webPort}"
#   interval : 1000
#   limits  :
#     memory   : 300
#     callback : ->
#       console.log "[WEBSERVER #{webPort}] I'm using too much memory, feeling suicidal."
#       process.exit()
processMonitor = (require 'processes-monitor').start
  name : "webServer on port #{webPort}"
  interval : 1000
  limits  :
    memory   : 300
    callback : ->
      console.log "[WEBSERVER #{webPort}] I'm using too much memory, feeling suicidal."
      #process.exit()

# if webPort is 3002
#   foo = []
#   do bar = ->
#    process.nextTick ->
#      foo.push Math.random()
#      bar()

#   setInterval ->
#    a=foo.length
#   , 1000


{extend} = require 'underscore'
express = require 'express'
Broker = require 'broker'
fs = require 'fs'
hat = require 'hat'
nodePath = require 'path'

app = express()

# this is a hack so express won't write the multipart to /tmp
#delete express.bodyParser.parse['multipart/form-data']

app.configure ->
  app.set 'case sensitive routing', on
  app.use express.cookieParser()
  app.use express.session {"secret":"foo"}
  app.use express.bodyParser()
  app.use express.compress()
  app.use express.static "#{projectRoot}/website/"

#app.use gzippo.staticGzip "#{projectRoot}/website/"
app.use (req, res, next)->
  res.removeHeader("X-Powered-By")
  next()

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException',(err)->
  console.log 'there was an uncaught exception'
  throw err
  console.trace()

koding = require './bongo'

kiteBroker =\
  if kites?.vhost?
    new Broker extend {}, mq, vhost: kites.vhost
  else
    koding.mq

koding.mq.connection.on 'ready', -> console.log 'message broker is ready'

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

app.get "/Logout", (req, res)->
  res.clearCookie 'clientId'
  res.redirect 302, '/'

app.get '/Auth', (req, res)->
  crypto = require 'crypto'
  {JSession} = koding.models
  channel = req.query?.channel
  return res.send 'user error', 400 unless channel?
  clientId = req.cookies.clientId
  JSession.fetchSession clientId, (err, session)->
    if session? and clientId isnt session?.clientId
      res.cookie 'clientId', session.clientId
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
        privName = ['secret', 'kite', "#{cipher.final('hex')}.#{username}"].join '-'
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

if uploads?.enableStreamingUploads
  
  s3 = require('./s3') uploads.s3

  app.post '/Upload', s3..., (req, res)->
    res.send(for own key, file of req.files
      filename  : file.filename
      resource  : nodePath.join uploads.distribution, file.path
    )

  app.get '/Upload/test', (req, res)->
    res.send \
      """
      <script>
        function submitForm(form) {
          var file, fld;
          input = document.getElementById('image');
          file = input.files[0];
          fld = document.createElement('input');
          fld.hidden = true;
          fld.name = input.name + '-size';
          fld.value = file.size;
          form.appendChild(fld);
          return true;
        }
      </script>
      <form method="post" action="/upload" enctype="multipart/form-data" onsubmit="return submitForm(this)">
        <p>Title: <input type="text" name="title" /></p>
        <p>Image: <input type="file" name="image" id="image" /></p>
        <p><input type="submit" value="Upload" /></p>
      </form>
      """

app.get "/", (req, res)->
  if frag = req.query._escaped_fragment_?
    res.send 'this is crawlable content'
  else
    # log.info "serving index.html"
    res.header 'Content-type', 'text/html'
    fs.readFile "#{projectRoot}/website/index.html", (err, data) ->
      throw err if err
      res.send data

app.get "/-/status/:event/:kiteName",(req,res)->
  # req.params.data
  
  obj =
    processName : req.params.kiteName
    # processId   : KONFIG.crypto.decrypt req.params.encryptedPid
  
  koding.mq.emit 'public-status', req.params.event, obj
  res.send "got it."


app.get "/-/api/user/:username/flags/:flag", (req, res)->
  {username, flag} = req.params
  {JAccount}       = koding.models

  JAccount.one "profile.nickname" : username, (err, account)->
    if err or not account
      state = false
    else
      state = account.checkFlag('super-admin') or account.checkFlag(flag)
    res.end "#{state}"

getAlias =do->
  caseSensitiveAliases = ['auth']
  (url)->
    rooted = '/' is url.charAt 0
    url = url.slice 1  if rooted
    if url in caseSensitiveAliases
      alias = "#{url.charAt(0).toUpperCase()}#{url.slice 1}"
    if alias and rooted then "/#{alias}" else alias

app.get '*', (req,res)->
  {url} = req
  queryIndex = url.indexOf '?'
  [urlOnly, query] =\
    if ~queryIndex then [url.slice(0, queryIndex), url.slice(queryIndex)]
    else [url, '']
  alias = getAlias urlOnly
  redirectTo = if alias then "#{alias}#{query}" else "/#!#{urlOnly}#{query}"
  res.header 'Location', redirectTo
  res.send 302

app.listen webPort

console.log 'Koding Webserver running ', "http://localhost:#{webPort}"
