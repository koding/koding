process.title = 'koding-webserver'
{ argv }      = require 'optimist'

Object.defineProperty global, \
  'KONFIG', { value : require 'koding-config-manager' }

{ webserver, projectRoot, basicAuth } = KONFIG

koding                = require './bongo'
express               = require 'express'
helmet                = require 'helmet'
bodyParser            = require 'body-parser'
metrics               = require '../../datadog'
usertracker           = require '../../../workers/usertracker'
app                   = express()
webPort               = argv.p ? webserver.port
{ error_500 }         = require './helpers'
{ generateHumanstxt } = require './humanstxt'
csrf                  = require './csrf'
setCrsfToken          = require './setcsrftoken'
{ NodejsProfiler }    = require 'koding-datadog'

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
  app.use bodyParser.urlencoded { extended : yes }
  app.use compression()
  # helmet:
  app.use helmet.xframe('sameorigin')
  app.use helmet.iexss()
  app.use helmet.ienoopen()
  app.use helmet.contentTypeOptions()
  app.use helmet.hidePoweredBy()
  app.use metrics.send


# handle basic auth
app.use express.basicAuth basicAuth.username, basicAuth.password  if basicAuth

# capture/log exceptions
process.on 'uncaughtException', require './handlers/uncaughtexception'

# this is for creating session for incoming user if it doesnt have
app.use require './setsession'

# ORDER IS IMPORTANT
# routes ordered as before no particular structure

app.post '/-/teams/validate-token'               , require './handlers/checktoken'
app.post '/-/teams/allow'                        , setCrsfToken, (req, res) -> res.json { token: req.pendingCookies._csrf }
app.post '/-/teams/create'                       , csrf,   require './handlers/createteam'
app.post '/-/teams/join'                         , csrf,   require './handlers/jointeam'
app.post '/-/teams/early-access'                 , require './handlers/earlyaccess'
app.post '/-/teams/verify-domain'                , require './handlers/verifyslug'
app.post '/-/teams/invite-by-csv'                , require('./handlers/invitetoteambycsv').handler
app.get  '/-/teams/check-team-invitation'        , require './handlers/teaminvitationchecker'

# fetches last members of team
app.all  '/-/team/:name/members'                 , require './handlers/getteammembers'
app.all  '/-/team/:name'                         , require './handlers/getteam'
app.all  '/-/profile/:email'                     , require './handlers/getprofile'
app.all  '/-/unsubscribe/:token/:email'          , require './handlers/unsubscribe'
# temp endpoints ends

app.post '/-/analytics/track'                    , require './handlers/analytics/track'
app.post '/-/analytics/page'                     , require './handlers/analytics/page'

app.get  '/-/my/permissionsAndRoles'             , require './handlers/myPermissionsAndRoles'
app.get  '/-/google-api/authorize/drive'         , require './handlers/authorizedrive'
app.get  '/-/auth/check/:key'                    , require './handlers/authkeycheck'
app.post '/-/support/new', bodyParser.json()     , require './handlers/supportnew'
app.get  '/-/auth/register/:hostname/:key'       , require './handlers/authregister'
# should deprecate those /Validates, they don't look like api endpoints
app.post '/:name?/Validate/Username/:username?'  , require './handlers/validateusername'
app.post '/:name?/Validate/Email/:email?'        , require './handlers/validateemail'
app.post '/:name?/Validate'                      , require './handlers/validate'
app.post '/-/password-strength'                  , require './handlers/passwordstrength'
app.post '/-/validate/username'                  , require './handlers/validateusername'
app.post '/-/validate/email'                     , require './handlers/validateemail'
app.post '/-/validate'                           , require './handlers/validate'
app.get  '/Verify/:token'                        , require './handlers/verifytoken'
app.post '/:name?/Register'                      , csrf,   require './handlers/register'
app.post '/:name?/Login'                         , csrf,   require './handlers/login'
app.post '/Impersonate/:nickname'                , csrf,   require './handlers/impersonate'
app.post '/:name?/Recover'                       , csrf,   require './handlers/recover'
app.post '/:name?/Reset'                         , csrf,   require './handlers/reset'
app.post '/:name?/Optout'                        , require './handlers/optout'
app.all  '/:name?/Logout'                        , csrf,   require './handlers/logout'
app.post '/:name?/Unregister'                    , require './handlers/unregister'
app.get  '/humans.txt'                           , generateHumanstxt
app.get  '/members/:username?*'                  , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get  '/w/members/:username?*'                , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get  '/activity/p/?*'                        , (req, res) -> res.redirect 301, '/Activity'
app.get  '/-/healthCheck'                        , require './handlers/healthcheck'
app.get  '/-/versionCheck'                       , require './handlers/versioncheck'
app.get  '/-/version'                            , (req, res) -> res.jsonp { version: KONFIG.version }
app.get  '/-/jobs'                               , require './handlers/jobs'
app.post '/recaptcha'                            , require './handlers/recaptcha'
app.get  '/-/presence/:service'                  , (req, res) -> res.status(200).end()
app.get  '/-/api/user/:username/flags/:flag'     , require './handlers/flaguser'
app.post '/-/api/user/create'                    , require './handlers/api/createuser'
app.post '/-/api/ssotoken/create'                , require './handlers/api/createssotoken'
app.get  '/-/api/ssotoken/login'                 , require './handlers/api/ssotokenlogin'
app.get  '/-/api/logs'                           , require './handlers/api/logs'
app.get  '/-/image/cache'                        , require './image_cache'
app.get  '/-/oauth/github/callback'              , require './github_callback'
app.get  '/-/oauth/gitlab/callback'              , require './gitlab_callback'
app.get  '/-/oauth/facebook/callback'            , require './facebook_callback'
app.get  '/-/oauth/google/callback'              , require './google_callback'
app.get  '/-/oauth/linkedin/callback'            , require './linkedin_callback'
app.get  '/-/oauth/twitter/callback'             , require './twitter_callback'
app.post '/:name?/OAuth'                         , require './oauth'
app.get  '/:name?/OAuth/url'                     , require './oauth_url'
app.get  '/-/subscriptions'                      , require './subscriptions'
app.get  '/-/payments/paypal/return'             , require './paypal_return'
app.get  '/-/payments/paypal/cancel'             , require './paypal_cancel'
app.get  '/-/payments/customers'                 , require './customers'
app.post '/-/payments/paypal/webhook'            , require './paypal_webhook'
app.post '/-/emails/subscribe'                   , (req, res) -> res.status(501).send 'ok'
app.post '/Hackathon2014/Apply'                  , require './handlers/hackathonapply'
# should deprecate those /Validates, they don't look like api endpoints
app.post '/Gravatar'                             , require './handlers/gravatar'
app.post '/-/gravatar'                           , require './handlers/gravatar'
app.get  '/Hackathon2014/:section?'              , require './handlers/hackathon'
app.get  '/-/confirm'                            , require './handlers/confirm'
app.get  '/:name?/Develop/?*'                    , (req, res) -> res.redirect 301, '/'
app.all  '/:name/:section?/:slug?'               , require './handlers/main.coffee'
app.get  '*'                                     , require './handlers/root.coffee'

# once bongo is ready we can start listening
koding.once 'dbClientReady', ->

  # start webserver
  app.listen webPort
  console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

  # start user tracking
  usertracker.start koding.redisClient

  # start monitoring nodejs metrics (memory, gc, cpu etc...)
  nodejsProfiler = new NodejsProfiler 'nodejs.webserver'
  nodejsProfiler.startMonitoring()

  # NOTE: in the event of errors, send 500 to the client rather
  #       than the stack trace.
  app.use (err, req, res, next) ->
    console.error 'request error'
    console.error err
    console.error err.stack
    res.status(500).send error_500()
