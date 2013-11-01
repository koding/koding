# TODO: we have to move kd related functions to somewhere else...

{argv} = require 'optimist'
Object.defineProperty global, 'KONFIG',
  value: require('koding-config-manager').load("main.#{argv.c}")

{
  webserver
  mq
  projectRoot
  kites
  uploads
  basicAuth
}       = KONFIG

webPort = argv.p ? webserver.port
koding  = require './bongo'
Crawler = require '../crawler'

processMonitor = (require 'processes-monitor').start
  name                : "webServer on port #{webPort}"
  stats_id            : "webserver." + process.pid
  interval            : 30000
  librato             : KONFIG.librato
  limit_hard          :
    memory            : 300
    callback          : ->
      console.log "[WEBSERVER #{webPort}] Using excessive memory, exiting."
      process.exit()
  die                 :
    after             : "non-overlapping, random, 3 digits prime-number of minutes"
    middleware        : (name,callback) -> koding.disconnect callback
    middlewareTimeout : 5000

_          = require 'underscore'
async      = require 'async'
{extend}   = require 'underscore'
express    = require 'express'
Broker     = require 'broker'
fs         = require 'fs'
hat        = require 'hat'
nodePath   = require 'path'
http       = require "https"
{JSession} = koding.models
app        = express()

{
  error_
  error_404
  error_500
  authenticationFailed
  findUsernameFromKey
  findUsernameFromSession
  fetchJAccountByKiteUserNameAndKey
  serve
  isLoggedIn
  getAlias
  addReferralCode
}          = require './helpers'

{ generateFakeClient } = require "./client"


# this is a hack so express won't write the multipart to /tmp
#delete express.bodyParser.parse['multipart/form-data']

app.configure ->
  app.set 'case sensitive routing', on
  app.use express.cookieParser()
  app.use express.session {"secret":"foo"}
  # app.use express.bodyParser()
  app.use express.compress()
  app.use express.static "#{projectRoot}/website/"

# disable express default header
app.disable 'x-powered-by'

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException',(err)->
  console.log 'there was an uncaught exception'
  console.log process.pid
  console.error err

app.use (req, res, next) ->
  # add referral code into session if there is one
  addReferralCode req, res

  {JSession} = koding.models
  {clientId} = req.cookies
  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress
  res.cookie "clientIPAddress", clientIPAddress, { maxAge: 900000, httpOnly: false }
  JSession.updateClientIP clientId, clientIPAddress, (err)->
    if err then console.log err
    next()

app.get "/-/8a51a0a07e3d456c0b00dc6ec12ad85c", require './__notify-users'

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
        console.log "ERROR - 0", err
        res.status 401
        res.send
          error: true
          message: "Koding Key not found. Error 2"
      else
        switch type
          when 'webserver'
            rabbitAPI.newProxyUser username, key, (err, data) =>
              if err?
                console.log "ERROR - 1", err
                res.send 401, JSON.stringify {error: "unauthorized - error code 1"}
              else
                postData =
                  key       : version
                  host      : 'localhost'
                  rabbitkey : key

                apiServer   = 'kontrol.in.koding.com'
                # local development
                # apiServer   = 'localhost:8000'

                options =
                  method  : 'POST'
                  uri     : "http://#{apiServer}/services/#{username}/#{name}"
                  body    : JSON.stringify postData
                  headers : {'content-type': 'application/json'}

                require('request').post options, (error, response, body) =>
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
                      messageBusUrl : 'koding.com:6380'

                    res.header "Content-Type", "application/json"
                    res.send JSON.stringify creds
          when 'openservice'
            rabbitAPI.newUser key, name, (err, data) =>
              if err?
                console.log "ERROR - 3", err
                res.send 401, JSON.stringify {error: "unauthorized - error code 2"}
              else
                creds =
                  protocol  : 'amqp'
                  host      : mq.apiAddress
                  username  : data.username
                  password  : data.password
                  vhost     : mq.vhost
                  messageBusUrl : 'koding.com:6380'

                {JUserKite} = koding.models
                JUserKite.fetchOrCreate
                  kitename      : name
                  latest_s3url  : "_"
                  account_id    : kodingKey.owner
                , (err, userkite)->
                  if err
                    console.log "error", err
                    return res.send err
                  userkite.newVersion (err)->
                    res.send err
                res.header "Content-Type", "application/json"
                res.send 200, JSON.stringify creds




s3 = require('./s3') uploads.s3, findUsernameFromKey
app.post "/-/kd/upload", s3..., (req, res)->
  {JUserKite} = koding.models
  for own key, file of req.files
    console.log "--------------------------------->>>>>>>>>>", req.account
    zipurl = "#{uploads.distribution}#{file.path}"
    JUserKite.fetchOrCreate
      kitename      : file.filename
      latest_s3url  : zipurl
      account_id    : req.account._id
      hash: req.fields.hash
    , (err, userkite)->
      if err
        console.log "error", err
        return res.send err
      userkite.newVersion (err)->
        if not err
          res.send {url:zipurl, version: userkite.latest_version, hash:req.fields.hash}
        else
          res.send err

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
          res.send 401
        else
          res.status 200
          res.send "OK"

app.get "/Logout", (req, res)->
  res.clearCookie 'clientId'
  res.redirect 302, '/'

app.get "/sitemap:sitemapName", (req, res)->
  {JSitemap}       = koding.models

  # may be written with a better understanding of express.js routing mechanism.
  sitemapName = req.params.sitemapName
  if sitemapName is ".xml"
    sitemapName = "sitemap.xml"
  else
    sitemapName = "sitemap" + sitemapName
  JSitemap.one "name" : sitemapName, (err, sitemap)->
    if err or not sitemap
      res.send 404
    else
      res.setHeader 'Content-Type', 'text/xml'
      res.send sitemap.content
    res.end

if uploads?.enableStreamingUploads

  s3 = require('./s3') uploads.s3, findUsernameFromSession

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
  # if services[service] and services[service].count > 0
  res.send 200
  # else
    # res.send 404

app.get '/-/services/:service', require './services-presence'

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

app.get "/-/oauth/odesk/callback",    require "./odesk_callback"
app.get "/-/oauth/github/callback",   require "./github_callback"
app.get "/-/oauth/facebook/callback", require "./facebook_callback"
app.get "/-/oauth/google/callback",   require "./google_callback"

app.all '/:name/:section?*', (req, res, next)->

  {JName, JGroup} = koding.models
  {name, section} = req.params
  return res.redirect 302, req.url.substring 7  if name in ['koding', 'guests']
  [firstLetter] = name

  if firstLetter.toUpperCase() is firstLetter
    unless section
    then next()
    else
      isLoggedIn req, res, (err, loggedIn, account)->
        prefix = if loggedIn then 'loggedIn' else 'loggedOut'
        if name is "Develop"
          subPage = JGroup.render[prefix].subPage {account, name, section}
          return serve subPage, res

        JName.fetchModels "#{name}/#{section}", (err, models)->
          if err
            subPage = JGroup.render[prefix].subPage {account, name, section}
            return serve subPage, res
          else unless models? then next()
          else
            subPage = JGroup.render[prefix].subPage {account, name, section, models}
            return serve subPage, res
  else
    isLoggedIn req, res, (err, loggedIn, account)->
      JName.fetchModels name, (err, models)->
        if err then next err
        else unless models? then res.send 404, error_404()
        else
          models.last.fetchHomepageView account, (err, view)->
            if err then next err
            else if view? then res.send view
            else res.send 500, error_500()

app.get "/", (req, res, next)->

  if slug = req.query._escaped_fragment_
    return Crawler.crawl koding, req, res, slug
  else

    {JGroup} = koding.models
    bongoModels = koding.models

    generateFakeClient req, res, (err, client)->
      if err or not client
        console.log err
        return next()

      isLoggedIn req, res, (err, loggedIn, account)->
        if err
          res.send 500, error_500()
          console.error err
        else if loggedIn
          # go to koding activity
          JGroup.render.loggedIn.kodingHome {client, account}, (err, activityPage)->
            return next()  if err
            serve activityPage, res
        else
          # go to koding home
          JGroup.render.loggedOut.kodingHome {client}, (err, homePage)->
            return next()  if err
            serve homePage, res


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

app.get '*', (req,res)->
  {url}            = req
  queryIndex       = url.indexOf '?'
  [urlOnly, query] =\
    if ~queryIndex
    then [url.slice(0, queryIndex), url.slice(queryIndex)]
    else [url, '']

  alias      = getAlias urlOnly
  redirectTo =\
    if alias
    then "#{alias}#{query}"
    else "/#!#{urlOnly}#{query}"

  res.header 'Location', redirectTo
  res.send 302

app.listen webPort
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"
