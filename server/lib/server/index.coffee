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
  authTemplate
  authCheckKey
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
  app.use express.bodyParser()
  app.use express.compress()
  # 86400000 == one day
  headers = {}
  if webserver.useCacheHeader
    headers.maxAge = 86400000

  app.use express.static( "#{projectRoot}/website/", headers)

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

app.get "/-/auth/check/:key", (req, res)->
  {key} = req.params

  console.log "checking for key"
  authCheckKey key, (ok, result) ->
    if not ok
      console.log "key is valid: #{result}" #keep up the result to us
      res.send 401, authTemplate "Key is not valid: '#{key}'"
      return

    {JKodingKey} = koding.models
    JKodingKey.fetchKey
      key     : key
    , (err, kodingKey)=>
      if err or not kodingKey
        res.send 401, authTemplate "Key doesn't exist"
        return

      res.send 200, {result: 'key is added successfully'}

app.get "/-/auth/register/:hostname/:key", (req, res)->
  {key, hostname} = req.params

  authCheckKey key, (ok, result) ->
    if not ok
      console.log "key is not valid: #{result}" #keep up the result to us
      res.send 401, authTemplate "Key is not valid: '#{key}'"
      return

    isLoggedIn req, res, (err, loggedIn, account)->
      if err
        # console.log "isLoggedIn error", err
        res.send 401, authTemplate "Koding Auth Error - 1"
        return

      if not loggedIn
        res.send 401, authTemplate "You are not logged in! Please log in with your Koding username and password"
        return

      findUsernameFromSession req, res, (err, notUsed, username) ->
        if err
          # console.log "findUsernameFromSession error", err
          res.send 401, authTemplate "Koding Auth Error - 2"
          return

        if not username
          res.send 401, authTemplate "Username is not defined: '#{username}'"
          return

        console.log "CREATING KEY WITH HOSTNAME: #{hostname} and KEY: #{key}"
        {JKodingKey} = koding.models
        JKodingKey.fetchByUserKey
          username: username
          key     : key
        , (err, kodingKey)=>
          if err or not kodingKey
            JKodingKey.createKeyByUser
              username : username
              hostname : hostname
              key      : key
            , (err, data) =>
              if err or not data
                # console.log "createKeyByUser error", key, err
                res.send 401, authTemplate "Koding Auth Error - 3"
              else
                res.send 200, authTemplate "Authentication is successfull! Using id: #{hostname}", key, hostname

          else
            res.send 200, authTemplate "Authentication already established!"


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

app.get "/-/api/app/:app"             , require "./applications"
app.get "/-/oauth/odesk/callback"     , require "./odesk_callback"
app.get "/-/oauth/github/callback"    , require "./github_callback"
app.get "/-/oauth/facebook/callback"  , require "./facebook_callback"
app.get "/-/oauth/google/callback"    , require "./google_callback"
app.get "/-/oauth/linkedin/callback"  , require "./linkedin_callback"
app.get "/-/oauth/twitter/callback"   , require "./twitter_callback"

app.get "/Landing/:page", (req, res, next) ->
  {page}      = req.params
  bongoModels = koding.models
  {JGroup}    = bongoModels

  generateFakeClient req, res, (err, client) ->
    isLoggedIn req, res, (err, loggedIn, account) ->
      JGroup.render.landing {account, page, client, bongoModels}, (err, body) ->
        serve body, res

# Handles all internal pages
# /USER || /SECTION || /GROUP[/SECTION] || /APP
#
app.all '/:name/:section?*', (req, res, next)->
  {JName, JGroup} = koding.models
  {name, section} = req.params
  return res.redirect 302, req.url.substring 7  if name in ['koding', 'guests']
  [firstLetter] = name

  # Checks if its an internal request like /Activity, /Terminal ...
  #
  if firstLetter.toUpperCase() is firstLetter
    unless section
    then next()
    else
      bongoModels = koding.models
      generateFakeClient req, res, (err, client)->

        isLoggedIn req, res, (err, loggedIn, account)->
          prefix   = if loggedIn then 'loggedIn' else 'loggedOut'
          serveSub = (err, subPage)->
            return next()  if err
            serve subPage, res

          # No need to use Develop anymore FIXME ~ GG
          if name is "Develop"
            options = {account, name, section, client, bongoModels}
            return JGroup.render[prefix].subPage options, serveSub

          JName.fetchModels "#{name}/#{section}", (err, models)->
            if err
              options = {account, name, section, client, bongoModels}
              JGroup.render[prefix].subPage options, serveSub
            else unless models? then next()
            else
              options = {account, name, section, models, client, bongoModels}
              JGroup.render[prefix].subPage options, serveSub

  # Checks if its a User or Group from JName collection
  #
  else
    isLoggedIn req, res, (err, loggedIn, account)->
      JName.fetchModels name, (err, models)->
        if err then next err
        else unless models? then res.send 404, error_404()
        else if models.last?
          models.last.fetchHomepageView account, (err, view)->
            if err then next err
            else if view? then res.send view
            else res.send 500, error_500()
        else next()

# Main Handler for Koding.com
#
app.get "/", (req, res, next)->

  # Handle crawler request
  #
  if req.query._escaped_fragment_?
    staticHome = require "../crawler/staticpages/kodinghome"
    slug = req.query._escaped_fragment_
    return res.send 200, staticHome() if slug is ""
    return Crawler.crawl koding, req, res, slug

  # User requests
  #
  else

    serveSub = (err, subPage)->
      return next()  if err
      serve subPage, res

    {JGroup} = bongoModels = koding.models

    generateFakeClient req, res, (err, client)->
      if err or not client
        console.log err
        return next()
      isLoggedIn req, res, (err, loggedIn, account)->
        if err
          res.send 500, error_500()
          return console.error err
        render = if loggedIn then JGroup.render.loggedIn \
                             else JGroup.render.loggedOut
        render.kodingHome {client, account, bongoModels}, serveSub

# Forwards to /
#
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
