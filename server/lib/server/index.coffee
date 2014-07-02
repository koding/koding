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

log4js  = require 'log4js'
logger  = log4js.getLogger("webserver")

log4js.configure {
  appenders: [
    { type: 'console' }
    { type: 'file', filename: 'logs/webserver.log', category: 'webserver' }
    { type: "log4js-node-syslog", tag : "webserver", facility: "local0", hostname: "localhost", port: 514 }
  ],
  replaceConsole: true
}

processMonitor = (require 'processes-monitor').start
  name                : "webServer on port #{webPort}"
  stats_id            : "webserver." + process.pid
  interval            : 30000
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
helmet     = require 'helmet'
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
}          = require './helpers'

{ generateFakeClient } = require "./client"
{ generateHumanstxt } = require "./humanstxt"


# this is a hack so express won't write the multipart to /tmp
#delete express.bodyParser.parse['multipart/form-data']

app.configure ->
  app.set 'case sensitive routing', on

  headers = {}
  if webserver.useCacheHeader
    headers.maxAge = 1000 * 60 * 60 * 24 # 1 day

  app.use express.static "#{projectRoot}/website/", headers
  app.use express.cookieParser()
  app.use express.session {"secret":"foo"}
  app.use express.bodyParser()
  app.use express.compress()
  # helmet:
  app.use helmet.xframe()
  app.use helmet.iexss()
  app.use helmet.ienoopen()
  app.use helmet.contentTypeOptions()
  app.use helmet.hidePoweredBy()

# disable express default header
app.disable 'x-powered-by'

if basicAuth
  app.use express.basicAuth basicAuth.username, basicAuth.password

process.on 'uncaughtException', (err) ->
  console.error " there was an uncaught exception #{err}"
  throw err
  process.exit(1)


# this is for creating session for incoming user if it doesnt have
app.use (req, res, next) ->
  {JSession} = koding.models
  {clientId} = req.cookies
  # fetchClient will validate the clientId.
  # if it is in our db it will return the session it
  # it it is not in db, creates a new one and returns it
  JSession.fetchSession clientId, (err, { session })->
    return next() if err or not session
    { maxAge, secure } = KONFIG.sessionCookie

    # set cookie as pending cookie
    req.pendingCookies or= {}
    req.pendingCookies.clientId = session.clientId

    res.cookie "clientId", session.clientId, { maxAge, secure }
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

  return res.send 401, { err: "TOKEN_REQUIRED"     } unless kiteToken
  return res.send 401, { err: "USERNAME_REQUIRED"  } unless user
  return res.send 401, { err: "GROUPNAME_REQUIRED" } unless groupId

  JKite.one kiteCode: kiteToken, (err, kite) ->
    return res.send 401, { err: "KITE_NOT_FOUND" }  if err or not kite

    JAccount.one { "profile.nickname": user }, (err, account) ->
      return res.send 401, err: "USER_NOT_FOUND"  if err or not account

      JGroup.one { "_id": groupId }, (err, group) =>
        return res.send 401, err: "GROUP_NOT_FOUND"  if err or not group

        group.isMember account, (err, isMember) =>
          return res.send 401, err: "NOT_A_MEMBER_OF_GROUP"  if err or not isMember

          kite.fetchPlans (err, plans) ->
            return res.send 401, err: "KITE_HAS_NO_PLAN"  if err or not plans

            planMap = {}
            planMap[plan.planCode] = plan  for plan in plans

            kallback = (err, subscriptions) ->
              return res.send 401, err: "NO_SUBSCRIPTION"  if err or not subscriptions

              freeSubscription = null
              paidSubscription = null
              for item in subscriptions
                if "nosync" in item.tags
                  freeSubscription = item
                else
                  paidSubscription = item

              subscription = paidSubscription or freeSubscription
              if subscription and plan = planMap[subscription.planCode]
                  res.send 200, planId: plan.planCode, planName: plan.title
              else
                res.send 401, err: "NO_SUBSCRIPTION"

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
    return res.send 401, authTemplate "Key doesn't exist" unless status
    res.send 200, {result: 'key is added successfully'}

app.get "/-/auth/register/:hostname/:key", (req, res)->
  {key, hostname} = req.params

  isLoggedIn req, res, (err, loggedIn, account)->
    return res.send 401, authTemplate "Koding Auth Error - 1" if err

    unless loggedIn
      errMessage = "You are not logged in! Please log in with your Koding username and password"
      res.send 401, authTemplate errMessage
      return

    unless account and account.profile and account.profile.nickname
      errMessage = "Your account is not found, it may be a system error"
      res.send 401, authTemplate errMessage
      return

    username = account.profile.nickname

    console.log "CREATING KEY WITH HOSTNAME: #{hostname} and KEY: #{key}"
    {JKodingKey} = koding.models
    JKodingKey.registerHostnameAndKey {username, hostname, key}, (err, data)=>
      if err
        res.send 401, authTemplate err.message
      else
        res.send 200, authTemplate data


app.all "/:name?/Logout", (req, res)->
  res.clearCookie 'clientId'  if req.method is 'POST'
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
  res.jsonp(result:1)

app.get "/-/version", (req, res) ->
  res.jsonp(version:KONFIG.version)

app.get "/-/jobs", (req, res) ->

  request = require 'request'
  options =
    url   : 'https://api.lever.co/v0/postings/koding'
    json  : yes

  request options, (err, r, postings) ->
    res.send 404 if err
    res.json postings

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

app.get "/-/presence/:service", (req, res) ->
  # if services[service] and services[service].count > 0
  res.send 200
  # else
    # res.send 404

app.get '/-/services/:service', require './services-presence'

app.get "/-/api/user/:username/flags/:flag", (req, res)->
  {username, flag} = req.params
  {JAccount}       = koding.models
  JAccount.one "profile.nickname" : username, (err, account)->
    if err or not account
      state = false
    else
      state = account.checkFlag('super-admin') or account.checkFlag(flag)
    res.end "#{state}"

app.get "/-/api/app/:app"            , require "./applications"
app.get "/-/oauth/odesk/callback"    , require "./odesk_callback"
app.get "/-/oauth/github/callback"   , require "./github_callback"
app.get "/-/oauth/facebook/callback" , require "./facebook_callback"
app.get "/-/oauth/google/callback"   , require "./google_callback"
app.get "/-/oauth/linkedin/callback" , require "./linkedin_callback"
app.get "/-/oauth/twitter/callback"  , require "./twitter_callback"
app.get '/-/image/cache'             , require "./image_cache"

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
app.all '/:name/:section?/:slug?*', (req, res, next)->
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
        return res.send 200, staticHome() if path is ""

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
      return res.send 404, error_404()  if err

      JName.fetchModels name, (err, result)->
        return next err  if err
        return res.send 404, error_404()  unless result?
        { models } = result
        if models.last?
          if models.last.bongo_?.constructorName isnt "JGroup" and not loggedIn
            return Crawler.crawl koding, {req, res, slug: name, isProfile: yes}

          generateFakeClient req, res, (err, client)->
            homePageOptions = { section, account, bongoModels,
                                isCustomPreview, client, params }

            models.last.fetchHomepageView homePageOptions, (err, view)->
              if err then next err
              else if view? then res.send view
              else res.send 404, error_404()
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
    return Crawler.crawl koding, {req, res, slug}

  # User requests
  #
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

  res.header 'Location', redirectTo
  res.send 301

app.listen webPort
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

# NOTE: in the event of errors, send 500 to the client rather
#       than the stack trace.
app.use (err, req, res, next) -> res.send 500, error_500()
