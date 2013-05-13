{argv} = require 'optimist'
Object.defineProperty global, 'KONFIG', {
  value: require('koding-config-manager').load("main.#{argv.c}")
}
{webserver, mongo, mq, projectRoot, kites, uploads, basicAuth, neo4j} = KONFIG

{loggedInPage, loggedOutPage} = require './staticpages'

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
async  = require 'async'

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

Graph = require "./graph/graph"
GraphDecorator = require "./graph/graph_decorator"

_fetchActivitiesByTimestamp = (req, res)->
  graph = new Graph neo4j
  #calculate the current and next timestamp

  timestamp = if req.params?.timestamp? then parseInt(req.params.timestamp, 10) else new Date
  startDate = new Date timestamp
  #20*60*1000 = 1200000
  endDate = new Date(startDate.getTime() + 1200000);

  graph.fetchAll startDate.toISOString(), endDate.toISOString(), (err, rawResponse)->
    # res.send rawResponse
    GraphDecorator.decorateSingle rawResponse, (decorated)->
      res.send decorated

app.get "/-/cache/latest", (req, res)->
  async.parallel [fetchInstalls, fetchFollows], (err, results)=>
    res.send decorateAll(err, results)

app.get "/-/cache/before/:timestamp", (req, res)->
  console.log "dfasdf"
  console.log  req.params
  console.log "d12341324"

  #_fetchActivitiesByTimestamp req, res

app.get "/-/cache/members", (req, res)->
  graph = new Graph neo4j
  graph.fetchNewMembers (err, rawResponse)->
    GraphDecorator.decorateMembers rawResponse, (decorated)->
      callback err, decorated

app.get "/-/cache/follows", (req, res)->
  graph = new Graph neo4j
  graph.fetchNewFollows (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decorated)->
      res.send decorated

startTime = null
app.get "/-/oldcache/latest", (req, res)->
  {JActivityCache} = koding.models
  startTime = Date.now()
  JActivityCache.latest (err, cache)->
    if err then console.warn err
    # console.log "latest: #{Date.now() - startTime} msecs!"
    return res.send if cache then cache.data else {}

app.get "/-/oldcache/before/:timestamp", (req, res)->
  {JActivityCache} = koding.models
  JActivityCache.before req.params.timestamp, (err, cache)->
    if err then console.warn err
    res.send if cache then cache.data else {}


app.get "/-/imageProxy", (req, res)->
  if req.query.url
    req.pipe(request(req.query.url)).pipe(res)
  else
    res.send 404

app.get "/-/kite/login", (req, res) ->
  rabbitAPI = require 'koding-rabbit-api'
  rabbitAPI.setMQ mq

  {JKite} = koding.models
  koding.models.JKite.control {key : req.query.key, kiteName : req.query.name}, (err, kite) =>
    res.header "Content-Type", "application/json"

    if err? or !kite?
      res.send 401
    else
      rabbitAPI.newUser req.query.key, kite.kiteName, (err, data) =>
        creds =
          protocol  : 'amqp'
          host      : mq.apiAddress
          username  : data.username
          password  : data.password
          vhost     : mq.vhost
        res.header "Content-Type", "application/json"
        res.send JSON.stringify creds

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
  [firstLetter] = name
  if firstLetter.toUpperCase() is firstLetter
    next()
  else
    JName.fetchModels name, (err, models)->
      if err then next err
      else unless models? then res.send 404, error_404()
      else
        {clientId} = req.cookies
        models[models.length-1].fetchHomepageView clientId, (err, view)->
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
          {username} = session?.data
          if username then serve loggedInPage, res
          else serve loggedOutPage, res

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

decorateAll = (err, decoratedObjects)->
  cacheObjects    = {}
  overviewObjects = []

  for objects in decoratedObjects
    for key, value of objects when key isnt "overview"
      cacheObjects[key] = value
    overviewObjects.push objects.overview

  overview = _.flatten overviewObjects

  response            = {}
  response.activities = cacheObjects
  response.overview   = overview
  response._id        = "1"
  response.isFull     = false
  response.from       = overview.first.createdAt.first
  response.to         = overview.last.createdAt.first
  response.newMemberBucketIndex = 1

  return response

fetchSingles = (callback)->
  _fetchSingles (err, rawResponse)->
    GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchFollows = (callback)->
  _fetchFollows (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchInstalls = (callback)->
  _fetchInstalls (err, rawResponse)->
    GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchMembers = (callback)->
  _fetchMembers (err, rawResponse)->
    GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

_fetchSingles = (callback)->
  graph = new Graph neo4j
  graph.fetchAll {}, {}, (err, rawResponse)->
    callback err, rawResponse

_fetchInstalls = (callback)->
  graph = new Graph neo4j
  graph.fetchNewInstalledApps (err, rawResponse)->
    callback err, rawResponse

_fetchFollows = (callback)->
  graph = new Graph neo4j
  graph.fetchNewFollows (err, rawResponse)->
    callback err, rawResponse

_fetchMembers = (callback)->
  graph = new Graph neo4j
  graph.fetchNewMembers (err, rawResponse)->
    callback err, rawResponse

console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"
