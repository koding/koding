process.title = 'koding-webserver'
{argv}        = require 'optimist'

Object.defineProperty global, 'KONFIG', value : require('koding-config-manager').load "main.#{argv.c}"

{
  webserver
  projectRoot
  basicAuth
} = KONFIG





koding                = require './bongo'
express               = require 'express'
helmet                = require 'helmet'
bodyParser            = require 'body-parser'
usertracker           = require '../../../workers/usertracker'
app                   = express()
webPort               = argv.p ? webserver.port
{ error_500 }         = require './helpers'
{ generateHumanstxt } = require "./humanstxt"


do ->
  cookieParser = require 'cookie-parser'
  session      = require 'express-session'
  compression  = require 'compression'

  app.set 'case sensitive routing', on

  headers = {}
  if webserver?.useCacheHeader
    headers.maxAge = 1000 * 60 * 60 * 24 # 1 day

  app.use express.static "#{projectRoot}/website/", headers
  app.use cookieParser()
  app.use session
    secret            : 'foo'
    resave            : yes
    saveUninitialized : true
  app.use bodyParser.urlencoded extended : yes
  app.use compression()
  # helmet:
  app.use helmet.xframe('sameorigin')
  app.use helmet.iexss()
  app.use helmet.ienoopen()
  app.use helmet.contentTypeOptions()
  app.use helmet.hidePoweredBy()

app.get "/-/8a51a0a07e3d456c0b00dc6ec12ad85c", require './__notify-users'

app.post '/:name?/Optout', (req, res) ->
  res.cookie 'useOldKoding', 'true'
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

# handle basic auth
app.use express.basicAuth basicAuth.username, basicAuth.password  if basicAuth


app.post '/:name?/Validate'                     , require './handlers/validate'
app.post '/:name?/Validate/Username/:username?' , require './handlers/validateusername'
app.post '/:name?/Validate/Email/:email?'       , require './handlers/validateemail'
app.post '/:name?/Register'                     , require './handlers/register'
app.post '/:name?/Login'                        , require './handlers/login'
app.post '/:name?/Recover'                      , require './handlers/recover'
app.post '/:name?/Reset'                        , require './handlers/reset'
app.post '/Impersonate/:nickname'               , require './handlers/impersonate'
app.all '/:name?/Logout'                        , require './handlers/logout'
# start webserver
app.listen webPort
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

# start user tracking
usertracker.start()

# init rabbitmq client for Email to use to queue emails
mqClient = require './amqp'
Email    = require '../../../workers/social/lib/social/models/email.coffee'
Email.setMqClient mqClient

# NOTE: in the event of errors, send 500 to the client rather
#       than the stack trace.
app.use (err, req, res, next) ->
  console.error "request error"
  console.error err
  console.error err.stack
  res.status(500).send error_500()
