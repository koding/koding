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





# handle basic auth
app.use express.basicAuth basicAuth.username, basicAuth.password  if basicAuth

# this is for creating session for incoming user if it doesnt have
app.use require './handlers/setsession'


# GET Routes
app.get '/-/subscription/check/:kiteToken?/:user?/:groupId?' , require './handlers/kitesubscription'
app.get '/-/8a51a0a07e3d456c0b00dc6ec12ad85c'   , require './__notify-users'
app.get '/-/google-api/authorize/drive'         , require './handlers/authorizedrive'
app.get '/-/auth/register/:hostname/:key'       , require './handlers/authregister'
app.get '/-/auth/check/:key'                    , require './handlers/authkeycheck'
app.get '/-/api/user/:username/flags/:flag'     , require './handlers/flaguser'
app.get '/-/api/app/:app'                       , require './applications'
app.get '/-/oauth/odesk/callback'               , require './odesk_callback'
app.get '/-/oauth/github/callback'              , require './github_callback'
app.get '/-/oauth/facebook/callback'            , require './facebook_callback'
app.get '/-/oauth/google/callback'              , require './google_callback'
app.get '/-/oauth/linkedin/callback'            , require './linkedin_callback'
app.get '/-/oauth/twitter/callback'             , require './twitter_callback'
app.get '/-/payments/paypal/return'             , require './paypal_return'
app.get '/-/payments/paypal/cancel'             , require './paypal_cancel'
app.get '/-/payments/customers'                 , require './customers'
app.get '/-/presence/:service'                  , (req, res) -> res.status(200).end()
app.get '/-/image/cache'                        , require './image_cache'
app.get '/-/subscriptions'                      , require './subscriptions'
app.get '/-/version'                            , (req, res) -> res.jsonp version: KONFIG.version
app.get '/-/healthCheck'                        , require './handlers/healthcheck'
app.get '/-/versionCheck'                       , require './handlers/versioncheck'
app.get '/-/jobs'                               , require './handlers/jobs'
app.get '/:name?/OAuth/url'                     , require './oauth_url'
app.get '/Verify/:token'                        , require './handlers/verifytoken'
app.get '/humans.txt'                           , generateHumanstxt
app.get '/Hackathon/:section?'                  , require './handlers/hackathon'
app.get '/'                                     , require './handlers/root.coffee'
app.get '*'                                     , require './handlers/rest.coffee'


# redirects
app.get '/members/:username?*'                  , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get '/w/members/:username?*'                , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get '/activity/p/?*'                        , (req, res) -> res.redirect 301, '/Activity'


# POST Routes
app.post '/-/video-chat/session'                , require './handlers/videosession'
app.post '/-/video-chat/token'                  , require './handlers/videotoken'
app.post '/-/support/new', bodyParser.json()    , require './handlers/supportnew'
app.post '/-/payments/paypal/webhook'           , require './paypal_webhook'
app.post '/-/emails/subscribe'                  , (req, res) -> res.status(501).send 'ok'
app.post '/:name?/Validate'                     , require './handlers/validate'
app.post '/:name?/Validate/Username/:username?' , require './handlers/validateusername'
app.post '/:name?/Validate/Email/:email?'       , require './handlers/validateemail'
app.post '/:name?/Register'                     , require './handlers/register'
app.post '/:name?/Login'                        , require './handlers/login'
app.post '/:name?/Recover'                      , require './handlers/recover'
app.post '/:name?/Reset'                        , require './handlers/reset'
app.post '/:name?/Optout'                       , require './handlers/optout'
app.post '/:name?/OAuth'                        , require './oauth'
app.post '/recaptcha'                           , require './handlers/recaptcha'
app.post '/Impersonate/:nickname'               , require './handlers/impersonate'
app.post '/Hackathon/Apply'                     , require './handlers/hackathonapply'
app.post '/Gravatar'                            , require './handlers/gravatar'

# GET/POST Routes
app.all '/:name?/Logout'                        , require './handlers/logout'
app.all '/:name/:section?/:slug?'               , require './handlers/main.coffee'

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
