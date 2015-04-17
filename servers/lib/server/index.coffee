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
} = KONFIG

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
bodyParser = require 'body-parser'
usertracker = require('../../../workers/usertracker')

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
} = require './helpers'

{ generateFakeClient, updateCookie } = require "./client"
{ generateHumanstxt } = require "./humanstxt"


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

videoSessions = {}
app.post '/-/video-chat/session', (req, res) ->

  { channelId } = req.body


  return res.status(400).send { err: 'Channel ID is required.'      }  unless channelId
  return res.status(200).send { sessionId: videoSessions[channelId] }  if videoSessions[channelId]

  { apiKey, apiSecret } = KONFIG.tokbox

  OpenTok = require 'opentok'

  opentok = new OpenTok apiKey, apiSecret

  opentok.createSession (err, session) ->

    videoSessions[channelId] = session.sessionId

    res.status(200).send { sessionId: session.sessionId }


app.post '/-/video-chat/token', (req, res) ->

  { role, sessionId } = req.body

  return res.status(400).send { err: "Session ID is required." } unless sessionId
  return res.status(400).send { err: "Role is required"        } unless role

  { apiKey, apiSecret } = KONFIG.tokbox

  OpenTok = require 'opentok'

  opentok = new OpenTok apiKey, apiSecret

  token = opentok.generateToken sessionId, { role }

  return res.status(200).send { token }


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

app.post '/:name?/Validate', (req, res) ->
  { JUser } = koding.models
  { fields } = req.body

  unless fields?
    res.status(400).send 'Bad request'
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


app.post '/:name?/Validate/Username/:username?', (req, res) ->

  { JUser } = koding.models
  { username } = req.params

  return res.status(400).send 'Bad request'  unless username?

  JUser.usernameAvailable username, (err, response) =>

    return res.status(400).send 'Bad request'  if err

    {kodingUser, forbidden} = response

    if not kodingUser and not forbidden
      res.status(200).send response
    else
      res.status(400).send response

app.post '/:name?/Validate/Email/:email?', (req, res) ->

  { JUser }    = koding.models
  { email }    = req.params
  { password } = req.body

  return res.status(400).send 'Bad request'  unless email?

  { password, redirect } = req.body

  clientId =  getClientId req, res

  if clientId

    JUser.login clientId, { username : email, password }, (err, info) ->

      {isValid : isEmail} = JUser.validateAt 'email', email, yes

      if err and isEmail
        JUser.emailAvailable email, (err_, response) =>
          return res.status(400).send 'Bad request'  if err_

          return if response
          then res.status(200).send response
          else res.status(400).send 'Email is taken!'

        return

      unless info
        return res.status(500).send 'An error occurred'

      res.cookie 'clientId', info.replacementToken, path : '/'
      return res.status(200).send 'User is logged in!'



app.get '/Verify/:token', (req, res) ->
  { JPasswordRecovery } = koding.models
  { token } = req.params

  JPasswordRecovery.validate token, (err, callback) ->
    return res.redirect 301, "/VerificationFailed"  if err?

    res.redirect 301, "/Verified"

app.post '/:name?/Register', (req, res) ->
  { JUser } = koding.models
  context = { group: 'koding' }
  { redirect } = req.body
  redirect ?= '/'
  clientId =  getClientId req, res

  return handleClientIdNotFound res, req unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->
    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    JUser.convert client, req.body, (err, result) ->

      if err?

        {message} = err

        if err.errors?
          message = "#{message}: #{Object.keys err.errors}"

        return res.status(400).send message


      res.cookie 'clientId', result.newToken, path : '/'
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
    if err
      return res.status(403).send err.message
    else if not info
      return res.status(500).send 'An error occurred'

    res.cookie 'clientId', info.replacementToken, path : '/'
    res.status(200).end()


app.post "/Impersonate/:nickname", (req, res) ->
  { JAccount, JSession } = koding.models
  {nickname} = req.params

  {clientId} = req.cookies

  JSession.fetchSession clientId, (err, result)->
    return res.status(400).end()  if err or not result

    { username } = result.session
    JAccount.one { "profile.nickname" : username }, (err, account) ->
      return res.status(400).end()  if err or not account

      unless account.can 'administer accounts'
        return res.status(403).end()

      JSession.createNewSession nickname, (err, session) ->
        return res.status(400).send err.message  if err

        JSession.remove {clientId}, (err) ->
          console.error 'Could not remove session:', err  if err

          res.cookie 'clientId', session.clientId, path : '/'  if session.clientId
          res.clearCookie 'realtimeToken'
          res.status(200).send({success: yes})


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

  JPasswordRecovery.resetPassword token, password, (err, username) ->
    return res.status(400).send err.message  if err?
    res.status(200).send({ username })

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
  {workers, publicPort} = KONFIG

  errs = []
  urls = []

  for own _, worker of workers
    urls.push worker.healthCheckURL  if worker.healthCheckURL

  urls.push("http://localhost:#{publicPort}/-/versionCheck")

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

app.get "/-/versionCheck", (req, res) ->
  errs = []
  urls = []
  for own key, val of KONFIG.workers
    urls.push {name: key, url: val.versionURL}  if val?.versionURL?

  urlFns = urls.map ({name, url})->->
    request url, (err, resp, body)->
      if err?
        errs.push({ name, err })
      else if KONFIG.version isnt body
        errs.push({ name, message: "versions are not same" })

      urlFns.fin()

  dash urlFns, ->
    if Object.keys(errs).length > 0
      console.log "VERSIONCHECK ERROR:", errs
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

# Handlers for Payment
app.get  '/-/subscriptions'          , require "./subscriptions"
app.get  '/-/payments/paypal/return' , require "./paypal_return"
app.get  '/-/payments/paypal/cancel' , require "./paypal_cancel"
app.post '/-/payments/paypal/webhook', require "./paypal_webhook"
app.get  '/-/payments/customers'     , require "./customers"

isInAppRoute = (name)->
  [firstLetter] = name
  # user nicknames can start with numbers
  intRegex = /^\d/
  return false if intRegex.test firstLetter
  return true  if firstLetter.toUpperCase() is firstLetter
  return false


app.post '/-/emails/subscribe', (req, res)->

  res.status(501).send 'ok'


app.post '/Hackathon/Apply', (req, res, next)->

  {JWFGH} = koding.models

  isLoggedIn req, res, (err, loggedIn, account)->

    return res.status(400).send 'not ok' unless loggedIn

    JWFGH.apply account, (err, stats)->
      return res.status(400).send err.message or 'not ok'  if err
      res.status(200).send stats


app.post '/Gravatar', (req, res) ->
  crypto  = require 'crypto'
  {email} = req.body

  console.log "Gravatar info request for: #{email}"

  _hash     = (crypto.createHash('md5').update(email.toLowerCase().trim()).digest('hex')).toString()
  _url      = "https://www.gravatar.com/#{_hash}.json"
  _request  =
    url     : _url
    headers : 'User-Agent': 'request'
    timeout : 3000

  request _request, (err, response, body) ->

    return res.status(400).send err.code  if err

    if body isnt 'User not found'
      try
        gravatar = JSON.parse body
      catch
        return res.status(400).send 'User not found'

      return res.status(200).send gravatar

    res.status(400).send body


app.get '/Hackathon/:section?', (req, res, next)->

  {JGroup} = koding.models

  isLoggedIn req, res, (err, loggedIn, account)->

    return next()  if err

    JGroup.render.loggedOut.kodingHome {
      campaign    : 'hackathon'
      bongoModels : koding.models
      loggedIn
      account
    }, (err, content) ->

      return next()  if err

      return res.status(200).send content



app.all '/:name/:section?/:slug?', (req, res, next)->

app.all '/:name/:section?/:slug?', (req, res, next)->
  {JName, JGroup} = koding.models

  {params} = req
  {name, section, slug} = params

  path = name
  path = "#{path}/#{section}"  if section
  path = "#{path}/#{slug}"     if slug

  # When we try to access /Activity/Message/New route, it is trying to
  # fetch message history with channel id = 'New' and returning:
  # Bad Request: strconv.ParseInt: parsing "New": invalid syntax error.
  # Did not like the way I resolve this, but this handler function is already
  # saying 'Refactor me' :)
  return next()  if section is 'Message' and slug is 'New'

  return res.redirect 301, req.url.substring 7  if name in ['koding', 'guests']
  # Checks if its an internal request like /Activity, /Terminal ...
  #
  bongoModels = koding.models

  if isInAppRoute name
    if name is 'Develop'
      return res.redirect 301, '/IDE'

    if name is 'Activity'
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
                          bongoModels, params }

              JGroup.render[prefix].subPage options, serveSub
            else if not result? then next()
            else
              { models } = result
              options = { account, name, section, models,
                          client, bongoModels, params }

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
                                client, params, loggedIn }

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

# start user tracking
usertracker.start()

# init rabbitmq client for Email to use to queue emails
mqClient = require './amqp'
Email = require '../../../workers/social/lib/social/models/email.coffee'
Email.setMqClient mqClient


# NOTE: in the event of errors, send 500 to the client rather
#       than the stack trace.
app.use (err, req, res, next) ->
  console.error "request error"
  console.error err
  console.error err.stack
  res.status(500).send error_500()
