{argv} = require 'optimist'
Object.defineProperty global, 'KONFIG', {
  value: require('koding-config-manager').load("main.#{argv.c}")
}

{webserver, mongo, mq, projectRoot, kites, uploads, basicAuth, neo4j} = KONFIG
page = require './staticpages'

webPort = argv.p ? webserver.port

processMonitor = (require 'processes-monitor').start
  name : "webServer on port #{webPort}"
  stats_id: "webserver." + process.pid
  interval : 30000
  librato: KONFIG.librato
  limit_hard  :
    memory   : 300
    callback : ->
      console.log "[WEBSERVER #{webPort}] Using excessive memory, exiting."
      process.exit()
  die :
    after: "non-overlapping, random, 3 digits prime-number of minutes"
    middleware : (name,callback) -> koding.disconnect callback
    middlewareTimeout : 5000

# Services (order is important here)
services =
  kite_webterm:
    pattern: 'webterm'
  worker_auth:
    pattern: 'auth'
  kite_applications:
    pattern: 'kite-application'
  kite_databases:
    pattern: 'kite-database'
  webserver:
    pattern: 'web'
  worker_social:
    pattern: 'social'

incService = (serviceKey, inc) ->
  for key, value of services
    if serviceKey.indexOf(value.pattern) > -1
      value.count = if value.count then value.count += inc else 1
      break

# Presences
koding = require './bongo'
koding.connect ->
  koding.monitorPresence
    join: (serviceKey) ->
      incService serviceKey, 1
    leave: (serviceKey) ->
      incService serviceKey, -1

# TODO: DRY this
_        = require 'underscore'
async    = require 'async'
{extend} = require 'underscore'
express  = require 'express'
Broker   = require 'broker'
request  = require 'request'
fs       = require 'fs'
hat      = require 'hat'
nodePath = require 'path'

app      = express()

# this is a hack so express won't write the multipart to /tmp
#delete express.bodyParser.parse['multipart/form-data']

app.configure ->
  app.set 'case sensitive routing', on
  app.use express.cookieParser()
  app.use express.session {"secret":"foo"}
  # app.use express.bodyParser()
  app.use express.compress()
  app.use express.static "#{projectRoot}/website/"

app.use (req, res, next)->
  res.removeHeader "X-Powered-By"
  next()

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException',(err)->
  console.log 'there was an uncaught exception'
  console.log process.pid
  console.error err
#    stack = err?.stack
#    console.log stack  if stack?

koding = require './bongo'

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

FetchAllActivityParallel = require './graph/fetch'
fetchFromNeo = (req, res)->
  timestamp  = req.params?.timestamp
  rawStartDate  = if timestamp? then parseInt(timestamp, 10) else (new Date).getTime()
  startDate  = Math.floor(rawStartDate/1000)

  console.log "fetchFromNeo", req.params.timestamp, rawStartDate, startDate

  fetch = new FetchAllActivityParallel startDate, neo4j
  fetch.get (results)->
    res.send results

app.get "/-/neo4j/latest", (req, res)->
  fetchFromNeo req, res

app.get "/-/neo4j/before/:timestamp", (req, res)->
  fetchFromNeo req, res

app.get "/-/cache/latest", (req, res)->
  {JActivityCache} = koding.models
  startTime = Date.now()
  JActivityCache.latest (err, cache)->
    if err then console.warn err
    # if you want to jump to previous cache - uncomment if needed
    if cache and req.query?.previous?
      timestamp = new Date(cache.from).getTime()
      return res.redirect 301, "/-/cache/before/#{timestamp}"
    # console.log "latest: #{Date.now() - startTime} msecs!"
    return res.send if cache then cache.data else {}

app.get "/-/cache/before/:timestamp", (req, res)->
  {JActivityCache} = koding.models
  JActivityCache.before req.params.timestamp, (err, cache)->
    if err then console.warn err
    # if you want to jump to previous cache - uncomment if needed
    if cache and req.query?.previous?
      timestamp = new Date(cache.from).getTime()
      return res.redirect 301, "/-/cache/before/#{timestamp}"
    res.send if cache then cache.data else {}

app.get "/-/imageProxy", (req, res)->
  if req.query.url
    req.pipe(request(req.query.url)).pipe(res)
  else
    res.send 404

app.get "/-/kite/login", (req, res) ->
  rabbitAPI = require 'koding-rabbit-api'
  rabbitAPI.setMQ mq

  res.header "Content-Type", "application/json"

  {username, key, name, type, version} = req.query

  unless username and key and name
    res.send
      error: true
      message: "Not enough parameters."
  else
    {JKodingKey} = koding.models

    JKodingKey.fetchByUserKey
      username: username
      key     : key
    , (err, kodingKey)=>
      if err or not kodingKey
        console.log "ERROR", err
        res.status 401
        res.send
          error: true
          message: "Koding Key not found. Error 2"
      else
        switch type
          when 'webserver'
            rabbitAPI.newProxyUser username, key, (err, data) =>
              if err?
                console.log "ERROR", err
                res.send 401, JSON.stringify {error: "unauthorized - error code 1"}
              else
                postData =
                  key       : version
                  host      : 'localhost'
                  rabbitkey : key

                apiServer   = 'kontrol.in.koding.com'
                proxyServer = 'proxy-2.in.koding.com'
                # local development
                # apiServer   = 'localhost:8000'
                # proxyServer = 'mahlika.local'

                options =
                  method  : 'POST'
                  uri     : "http://#{apiServer}/proxies/#{proxyServer}/services/#{username}/#{name}"
                  body    : JSON.stringify postData
                  headers : {'content-type': 'application/json'}

                request.post options, (error, response, body) =>
                  if error
                    console.log "ERROR", error
                    res.send 401, JSON.stringify {error: "unauthorized - error code 2"}
                  else if response.statusCode is 200
                    creds =
                      protocol  : 'amqp'
                      host      : "kontrol.in.koding.com"
                      username  : data.username
                      password  : data.password
                      vhost     : "/"
                      publicUrl : body

                    res.header "Content-Type", "application/json"
                    res.send JSON.stringify creds
          when 'openservice'
            rabbitAPI.newUser key, name, (err, data) =>
              if err?
                console.log "ERROR", err
                res.send 401, JSON.stringify {error: "unauthorized - error code 2"}
              else
                creds =
                  protocol  : 'amqp'
                  host      : mq.apiAddress
                  username  : data.username
                  password  : data.password
                  vhost     : mq.vhost
                console.log creds
                res.header "Content-Type", "application/json"
                res.send 200, JSON.stringify creds

# gate for kd
app.post "/-/kd/:command", express.bodyParser(), (req, res)->
  switch req.params.command
    when "register-check"
      {username, key} = req.body
      {JKodingKey} = koding.models

      JKodingKey.fetchByUserKey
        username: username
        key     : key
      , (err, kodingKey)=>
        if err or not kodingKey
          res.send 418 # I'm a teapot :P
        else
          res.status 200
          res.send "OK"

app.get "/Logout", (req, res)->
  res.clearCookie 'clientId'
  res.redirect 302, '/'

if uploads?.enableStreamingUploads

  s3 = require('./s3') uploads.s3

  app.post '/Upload', s3..., (req, res)->
    res.send(for own key, file of req.files
      filename  : file.filename
      resource  : nodePath.join uploads.distribution, file.path
    )

  # app.get '/Upload/test', (req, res)->
  #   res.send \
  #     """
  #     <script>
  #       function submitForm(form) {
  #         var file, fld;
  #         input = document.getElementById('image');
  #         file = input.files[0];
  #         fld = document.createElement('input');
  #         fld.hidden = true;
  #         fld.name = input.name + '-size';
  #         fld.value = file.size;
  #         form.appendChild(fld);
  #         return true;
  #       }
  #     </script>
  #     <form method="post" action="/upload" enctype="multipart/form-data" onsubmit="return submitForm(this)">
  #       <p>Title: <input type="text" name="title" /></p>
  #       <p>Image: <input type="file" name="image" id="image" /></p>
  #       <p><input type="submit" value="Upload" /></p>
  #     </form>
  #     """

app.get "/-/presence/:service", (req, res) ->
  {service} = req.params
  if services[service] and services[service].count > 0
    res.send 200
  else
    res.send 404

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

error_ =(code, message)->
  messageHTML = message.split('\n')
    .map((line)-> "<p>#{line}</p>")
    .join '\n'
  """
  <title>#{code}</title>
  <h1>#{code}</h1>
  #{messageHTML}
  """

error_404 =->
  error_ 404,
    """
    not found
    fayamf
    """

error_500 =->
  error_ 500, 'internal server error'

app.get '/:name/:section?*', (req, res, next)->
  {JGroup, JName, JSession} = koding.models
  {name} = req.params
  return res.redirect 302, req.url.substring 7  if name is 'koding'
  [firstLetter] = name
  if firstLetter.toUpperCase() is firstLetter
    next()
  else
    JName.fetchModels name, (err, models)->
      if err then next err
      else unless models? then res.send 404, error_404()
      else
        models[models.length-1].fetchHomepageView (err, view)->
          if err then next err
          else if view? then res.send view
          else res.send 500, error_500()

  # groupName = name
  # JGroup.one { slug: groupName }, (err, group)->
  #   if err or !group? then next err
  #   else
  #     group.fetchHomepageView (err, view)->
  #       if err then next err
  #       else res.send view

# app.get '/:userName', (req, res, next)->
#   {JAccount} = koding.models
#   {userName} = req.params
#   JAccount.one { 'profile.nickname': userName }, (err, account)->
#     if err or !account? then next err
#     else
#       if account.profile.staticPage?.show is yes
#         account.fetchHomepageView (err, view)->
#           if err then next err
#           else res.send view
#       else
#         res.header 'Location', '/Activity'
#         res.send 302

serve = (content, res)->
  res.header 'Content-type', 'text/html'
  res.send content

app.get "/", (req, res)->
  if frag = req.query._escaped_fragment_?
    res.send 'this is crawlable content'
  else
    defaultTemplate = require './staticpages'
    serve defaultTemplate, res

###
app.get "/-/kd/register/:key", (req, res)->
  {clientId} = req.cookies
  unless clientId
    serve loggedOutPage, res
  else
    {JSession} = koding.models
    JSession.one {clientId}, (err, session)=>
      if err
        console.error err
        serve loggedOutPage, res
      else
        {username} = session.data
        unless username
          res.redirect 302, '/'
        else
          JUser.one {username, status: $ne: "blocked"}, (err, user) =>
          if err
            res.redirect 302, '/'
          else unless user?
            res.redirect 302, '/'
          else
            user.fetchAccount "koding", (err, account)->
              {key} = req.params
              JPublicKey.create {connection: {delegate: account}}, {key}, (err, publicKey)->
                res.send "true"
###
getAlias = do->
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
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"
