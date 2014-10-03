# TODO: we have to move kd related functions to somewhere else...

process.title = 'koding-webserver'
{argv} = require 'optimist'
Object.defineProperty global, 'KONFIG',
  value: require('koding-config-manager').load("main.#{argv.c}")

{
  webserver
  projectRoot
  kites
  uploads
  basicAuth
  social
  broker
  recaptcha
}       = KONFIG

webPort = argv.p ? webserver.port
koding  = require './bongo'
Crawler = require '../crawler'
{dash}  = require 'bongo'

_          = require 'underscore'
async      = require 'async'
{extend}   = require 'underscore'
express    = require 'express'
Broker     = require 'broker'
fs         = require 'fs'
hat        = require 'hat'
nodePath   = require 'path'
http       = require "https"
helmet     = require 'helmet'
request    = require 'request'

{JSession} = koding.models
app        = express()

{
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  findUsernameFromKey
  findUsernameFromSession
  fetchJAccountByKiteUserNameAndKey
  serve
  serveHome
  isLoggedIn
  getAlias
  addReferralCode
  handleClientIdNotFound
  getClientId
}          = require './helpers'

{ generateFakeClient, updateCookie } = require "./client"
{ generateHumanstxt } = require "./humanstxt"

bodyParser = require 'body-parser'

do ->
  cookieParser = require 'cookie-parser'
  session = require 'express-session'
  compression = require 'compression'

  app.set 'case sensitive routing', on

  headers = {}
  if webserver?.useCacheHeader
    headers.maxAge = 1000 * 60 * 60 * 24 # 1 day

  app.use express.static "#{projectRoot}/website/", headers
  app.use cookieParser()
  app.use session
    secret: "foo"
    resave: yes
    saveUninitialized: true
  app.use bodyParser.urlencoded()
  app.use compression()
  # helmet:
  app.use helmet.xframe('sameorigin')
  app.use helmet.iexss()
  app.use helmet.ienoopen()
  app.use helmet.contentTypeOptions()
  app.use helmet.hidePoweredBy()

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException', (err) ->
  console.error " ------ FIX ME ------ @chris"
  console.error " there was an uncaught exception", err
  console.error err.stack
  console.error " ------ FIX ME ------ @chris"
  # process.exit 1


# app.post "/inbound",(req,res)->
#   console.log  "ok"
#   console.log req.body
#   res.send "ok"
#   return

# this is for creating session for incoming user if it doesnt have
app.use (req, res, next) ->
  {JSession} = koding.models
  {clientId} = req.cookies
  # fetchClient will validate the clientId.
  # if it is in our db it will return the session it
  # it it is not in db, creates a new one and returns it
  JSession.fetchSession clientId, (err, { session })->
    return next() if err or not session
    updateCookie req, res, session

    next()

app.use (req, res, next) ->
  # add referral code into session if there is one
  addReferralCode req, res

  {JSession} = koding.models
  {clientId} = req.cookies
  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress
  res.cookie "clientIPAddress", clientIPAddress, { maxAge: 900000, httpOnly: no }
  JSession.updateClientIP clientId, clientIPAddress, (err)->
    if err then console.log err
    next()


app.get "/-/subscription/check/:kiteToken?/:user?/:groupId?", (req, res) ->
  {kiteToken, user, groupId} = req.params
  {JAccount, JKite, JGroup}  = koding.models

  return res.status(401).send { err: "TOKEN_REQUIRED"     } unless kiteToken
  return res.status(401).send { err: "USERNAME_REQUIRED"  } unless user
  return res.status(401).send { err: "GROUPNAME_REQUIRED" } unless groupId

  JKite.one kiteCode: kiteToken, (err, kite) ->
    return res.status(401).send { err: "KITE_NOT_FOUND" }  if err or not kite

    JAccount.one { "profile.nickname": user }, (err, account) ->
      return res.status(401).send err: "USER_NOT_FOUND"  if err or not account

      JGroup.one { "_id": groupId }, (err, group) =>
        return res.status(401).send err: "GROUP_NOT_FOUND"  if err or not group

        group.isMember account, (err, isMember) =>
          return res.status(401).send err: "NOT_A_MEMBER_OF_GROUP"  if err or not isMember

          kite.fetchPlans (err, plans) ->
            return res.status(401).send err: "KITE_HAS_NO_PLAN"  if err or not plans

            planMap = {}
            planMap[plan.planCode] = plan  for plan in plans

            kallback = (err, subscriptions) ->
              return res.status(401).send err: "NO_SUBSCRIPTION"  if err or not subscriptions

              freeSubscription = null
              paidSubscription = null
              for item in subscriptions
                if "nosync" in item.tags
                  freeSubscription = item
                else
                  paidSubscription = item

              subscription = paidSubscription or freeSubscription
              if subscription and plan = planMap[subscription.planCode]
                  res.status(200).send planId: plan.planCode, planName: plan.title
              else
                res.status(401).send err: "NO_SUBSCRIPTION"

            if group.slug is "koding"
              targetOptions =
                selector    :
                  tags      : "vm"
                  planCode  : $in: (plan.planCode for plan in plans)
              account.fetchSubscriptions null, {targetOptions}, kallback
            else
              group.fetchSubscriptions kallback


app.get "/-/8a51a0a07e3d456c0b00dc6ec12ad85c", require './__notify-users'

app.get "/-/auth/check/:key", (req, res)->
  {key} = req.params

  {JKodingKey} = koding.models
  JKodingKey.checkKey {key}, (err, status)=>
    return res.status(401).send authTemplate "Key doesn't exist" unless status
    res.status(200).send {result: 'key is added successfully'}

app.post "/-/support/new", bodyParser.json(), (req, res)->

  isLoggedIn req, res, (err, loggedIn, account)->
    return res.status(401).send authTemplate "Koding Auth Error - 1"  if err

    unless loggedIn
      errMessage = "You are not logged in! Please log in with your Koding username and password"
      res.status(401).send authTemplate errMessage
      return

    unless account and account.profile and account.profile.nickname
      errMessage = "Your account is not found, it may be a system error"
      res.status(401).send authTemplate errMessage
      return

    (require './helpscout') account, req, res


app.get "/-/auth/register/:hostname/:key", (req, res)->
  {key, hostname} = req.params

  isLoggedIn req, res, (err, loggedIn, account)->
    return res.status(401).send authTemplate "Koding Auth Error - 1" if err

    unless loggedIn
      errMessage = "You are not logged in! Please log in with your Koding username and password"
      res.status(401).send authTemplate errMessage
      return

    unless account and account.profile and account.profile.nickname
      errMessage = "Your account is not found, it may be a system error"
      res.status(401).send authTemplate errMessage
      return

    username = account.profile.nickname

    console.log "CREATING KEY WITH HOSTNAME: #{hostname} and KEY: #{key}"
    {JKodingKey} = koding.models
    JKodingKey.registerHostnameAndKey {username, hostname, key}, (err, data)=>
      if err
        res.status(401).send authTemplate err.message
      else
        res.status(200).send authTemplate data

app.post "/:name?/Validate", (req, res) ->
  { JUser } = koding.models
  { fields } = req.body

  unless fields?
    res.status(400).send "Bad request"
    return

  validations = Object.keys fields
    .filter (key) -> key in ['username', 'email']
    .reduce (memo, key) ->
      { isValid, message } = JUser.validateAt key, fields[key], yes
      memo.fields[key] = { isValid, message }
      memo.isValid = no  unless isValid
      memo
    , { fields: {} }

  res.status(if validations.isValid then 200 else 400).send validations


app.post "/:name?/Validate/Username/:username?", (req, res) ->

  { JUser } = koding.models
  { username } = req.params

  return res.status(400).send 'Bad request'  unless username?

  JUser.usernameAvailable username, (err, response) =>
    return res.status(400).send 'Bad request'  if err

    {kodingUser, forbidden} = response

    if not kodingUser and not forbidden
      res.status(200).send response
    else if kodingUser
      res.status(400).send response

app.post "/:name?/Validate/Email/:email?", (req, res) ->

  { JUser } = koding.models
  { email } = req.params

  return res.status(400).send 'Bad request'  unless email?

  JUser.emailAvailable email, (err, response) =>
    return res.status(400).send 'Bad request'  if err

    return if response
    then res.status(200).send response
    else res.status(400).send 'Email is taken!'


app.get "/Verify/:token", (req, res) ->
  { JPasswordRecovery } = koding.models
  { token } = req.params

  JPasswordRecovery.validate token, (err, callback) ->
    return res.redirect 301, "/VerificationFailed"  if err?

    res.redirect 301, "/Verified"

app.post "/:name?/Register", (req, res) ->
  { JUser } = koding.models
  context = { group: 'koding' }
  { redirect } = req.body
  redirect ?= '/'
  clientId =  getClientId req, res

  return handleClientIdNotFound res, req unless clientId

  koding.fetchClient clientId, context, (client) ->
    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    JUser.convert client, req.body, (err, result) ->
      return res.status(400).send err.message  if err?

      res.cookie 'clientId', result.newToken
      # handle the request as an XHR response:
      return res.status(200).end() if req.xhr
      # handle the request with an HTTP redirect:
      res.redirect 301, redirect

app.post "/:name?/Login", (req, res) ->
  { JUser } = koding.models
  { username, password, redirect } = req.body

  clientId =  getClientId req, res

  return handleClientIdNotFound res, req unless clientId

  JUser.login clientId, { username, password }, (err, info) ->
    return res.status(403).send err.message  if err?
    # implementing a temporary opt-out for new koding:
    storageOptions =
      appId   : 'NewKoding'
      version : '2.0'
    info.account.fetchOrCreateAppStorage storageOptions, (err, appStorage) ->
      return res.status(500).send 'Internal error'  if err?
      res.cookie 'clientId', info.replacementToken
      res.status(200).end()

app.post "/:name?/Recover", (req, res) ->
  { JPasswordRecovery } = koding.models
  { email } = req.body

  return res.status(400).send 'Invalid email!'  if not email

  JPasswordRecovery.recoverPasswordByEmail { email }, (err) ->
    return res.status(403).send err.message  if err?

    res.status(200).end()

app.post '/:name?/Reset', (req, res) ->
  { JPasswordRecovery } = koding.models
  { recoveryToken: token, password } = req.body

  return res.status(400).send 'Invalid token!'  if not token
  return res.status(400).send 'Invalid password!'  if not password

  JPasswordRecovery.resetPassword { token, password }, (err, username) ->
    return res.status(400).send err.message  if err?
    res.status(200).end()

app.post '/:name?/Optout', (req, res) ->
  res.cookie 'useOldKoding', 'true'
  res.redirect 301, '/'

app.all "/:name?/Logout", (req, res)->
  if req.method is 'POST'
    res.clearCookie 'clientId'
    res.clearCookie 'useOldKoding'
    res.clearCookie 'koding082014'

  res.redirect 301, '/'

app.get "/humans.txt", (req, res)->
  generateHumanstxt(req, res)

app.get "/members/:username?*", (req, res)->
  username = req.params.username
  res.redirect 301, '/' + username

app.get "/w/members/:username?*", (req, res)->
  username = req.params.username
  res.redirect 301, '/' + username

app.get "/activity/p/?*", (req, res)->
  res.redirect 301, '/Activity'

app.get "/-/healthCheck", (req, res) ->
  {socialapi, newkontrol, publicPort} = KONFIG
  {socialApiUri, broker} = KONFIG.client.runtimeOptions

  errs = []
  urls = [
    socialapi.proxyUrl
    newkontrol.url
    "http://localhost:#{publicPort}#{socialApiUri}"
    "http://localhost:#{publicPort}#{broker.uri}/info"
    "http://localhost:#{publicPort}/kloud/kite/info"
  ]

  urlFns = urls.map (url)->->
    request url, (err, resp, body)->
      errs.push({ url, err })  if err?
      urlFns.fin()

  dash urlFns, ->
    if Object.keys(errs).length > 0
      console.log "HEALTHCHECK ERROR:", errs
      res.status(500).end()
    else
      res.status(200).end()

app.get "/-/version", (req, res) ->
  res.jsonp(version:KONFIG.version)

app.get "/-/jobs", (req, res) ->

  options =
    url   : 'https://api.lever.co/v0/postings/koding'
    json  : yes

  request options, (err, r, postings) ->
    res.status(404).send "Not found" if err
    res.json postings

simple_recaptcha = require "simple-recaptcha"

app.post "/recaptcha", (req, res)->
  {challenge, response} = req.body

  simple_recaptcha recaptcha, req.ip, challenge, response, (err)->
    if err
      res.send err.message
      return

    res.send "verified"

app.get "/sitemap.xml", (req, res)->
  getSiteMap "/sitemap.xml", req, res

app.get "/sitemap/:sitemapName", (req, res)->
  getSiteMap "/sitemap/#{req.params.sitemapName}", req, res

getSiteMap = (name, req, res)->
  {
    bareRequest
  } = require "../../../workers/social/lib/social/models/socialapi/helper"

  bareRequest "getSiteMap", {name:name}, (err, result)->
    res.setHeader "Content-Type", "text/xml"
    res.send result
    res.end

app.get "/-/presence/:service", (req, res) ->
  # if services[service] and services[service].count > 0
  res.status(200).end()
  # else
    # res.send 404

# deprecated.
# app.get '/-/services/:service', require './services-presence'

app.get "/-/api/user/:username/flags/:flag", (req, res)->
  {username, flag} = req.params
  {JAccount}       = koding.models
  JAccount.one "profile.nickname" : username, (err, account)->
    if err or not account
      state = false
    else
      state = account.checkFlag('super-admin') or account.checkFlag(flag)
    res.end "#{state}"

app.get "/-/api/app/:app" , require "./applications"
app.get '/-/image/cache'  , require "./image_cache"

# Handlers for OAuth
app.get  "/-/oauth/odesk/callback"    , require  "./odesk_callback"
app.get  "/-/oauth/github/callback"   , require  "./github_callback"
app.get  "/-/oauth/facebook/callback" , require  "./facebook_callback"
app.get  "/-/oauth/google/callback"   , require  "./google_callback"
app.get  "/-/oauth/linkedin/callback" , require  "./linkedin_callback"
app.get  "/-/oauth/twitter/callback"  , require  "./twitter_callback"
app.post "/:name?/OAuth"              , require  "./oauth"
app.get  "/:name?/OAuth/url"          , require  "./oauth_url"

bodyParser = require 'body-parser'
app.post '/-/stripe/webhook' , bodyParser.json(), require "./stripe_webhook"

app.get  '/-/subscriptions'  , require "./subscriptions"

# TODO: we need to add basic auth!
app.all '/-/email/webhook', (req, res) ->
  { JMail } = koding.models
  { body: batch } = req

  for item in batch when item.event is 'delivered'
    JMail.markDelivered item, (err) ->
      console.warn err  if err

  res.send 'ok'

isInAppRoute = (name)->
  [firstLetter] = name
  # user nicknames can start with numbers
  intRegex = /^\d/
  return false if intRegex.test firstLetter
  return true  if firstLetter.toUpperCase() is firstLetter
  return false

# Handles all internal pages
# /USER || /SECTION || /GROUP[/SECTION] || /APP
#
app.all '/:name/:section?/:slug?', (req, res, next)->
  {JName, JGroup} = koding.models

  {params} = req
  {name, section, slug} = params
  isCustomPreview = req.cookies["custom-partials-preview-mode"]

  path = name
  path = "#{path}/#{section}"  if section
  path = "#{path}/#{slug}"     if slug

  return res.redirect 301, req.url.substring 7  if name in ['koding', 'guests']
  # Checks if its an internal request like /Activity, /Terminal ...
  #
  bongoModels = koding.models

  if isInAppRoute name
    if name is 'Develop'
      return res.redirect 301, '/Terminal'

    if name in ['Activity']
      isLoggedIn req, res, (err, loggedIn, account)->

        return  serveHome req, res, next  if loggedIn
        staticHome = require "../crawler/staticpages/kodinghome"
        return res.status(200).send staticHome() if path is ""

        return Crawler.crawl koding, {req, res, slug: path}

    else

      generateFakeClient req, res, (err, client)->

        isLoggedIn req, res, (err, loggedIn, account)->
          prefix   = if loggedIn then 'loggedIn' else 'loggedOut'

          serveSub = (err, subPage)->
            return next()  if err
            serve subPage, res

          path = if section then "#{name}/#{section}" else name

          JName.fetchModels path, (err, result) ->

            if err
              options = { account, name, section, client,
                          bongoModels, isCustomPreview,
                          params }

              JGroup.render[prefix].subPage options, serveSub
            else if not result? then next()
            else
              { models } = result
              options = { account, name, section, models,
                          client, bongoModels, isCustomPreview,
                          params }

              JGroup.render[prefix].subPage options, serveSub

  # Checks if its a User or Group from JName collection
  #
  else
    isLoggedIn req, res, (err, loggedIn, account)->
      return res.status(404).send error_404()  if err

      JName.fetchModels name, (err, result)->
        return next err  if err
        return res.status(404).send error_404()  unless result?
        { models } = result
        if models.last?
          if models.last.bongo_?.constructorName isnt "JGroup" and not loggedIn
            return Crawler.crawl koding, {req, res, slug: name, isProfile: yes}

          generateFakeClient req, res, (err, client)->
            homePageOptions = { section, account, bongoModels,
                                isCustomPreview, client, params, loggedIn }

            models.last.fetchHomepageView homePageOptions, (err, view)->
              if err then next err
              else if view? then res.send view
              else res.status(404).send error_404()
        else next()

# Main Handler for Koding.com
#
app.get "/", (req, res, next)->
  if req.query._escaped_fragment_?
    staticHome = require "../crawler/staticpages/kodinghome"
    slug = req.query._escaped_fragment_
    return res.status(200).send staticHome() if slug is ""
    return Crawler.crawl koding, {req, res, slug}
  else
    serveHome req, res, next


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

  res.redirect 301, redirectTo

app.listen webPort
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

# NOTE: in the event of errors, send 500 to the client rather
#       than the stack trace.
app.use (err, req, res, next) ->
  console.error "request error"
  console.error err
  console.error err.stack
  res.status(500).send error_500()
