process.title = 'koding-webserver'

require 'coffee-cache'

{ argv } = require 'optimist'

Object.defineProperty global, \
  'KONFIG', { value : require 'koding-config-manager' }

{ webserver, projectRoot, basicAuth } = KONFIG

koding                = require './bongo'
express               = require 'express'
helmet                = require 'helmet'
bodyParser            = require 'body-parser'
metrics               = require '../../datadog'
app                   = express()
webPort               = argv.p ? webserver.port
{ error_500 }         = require './helpers'
{ generateHumanstxt } = require './humanstxt'
csrf                  = require './csrf'
setCrsfToken          = require './setcsrftoken'

do require './readclientversion'

do ->
  cookieParser = require 'cookie-parser'
  app.set 'case sensitive routing', on

  app.use cookieParser() # used by req.cookies.blah
  app.use bodyParser.urlencoded { extended : yes }
  # helmet:
  app.use helmet.frameguard { action: 'sameorigin' }
  app.use helmet.xssFilter()
  app.use helmet.ieNoOpen()
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
app.post '/-/teams/allow'                        , setCrsfToken
app.post '/-/teams/create'                       , csrf,   require './handlers/createteam'
app.post '/-/teams/join'                         , csrf,   require './handlers/jointeam'
app.post '/-/teams/verify-domain'                , require './handlers/verifyslug'
app.post '/-/teams/invite-by-csv'                , require('./handlers/invitetoteambycsv').handler
app.post '/-/teams/invite-by-csv-analyze'        , require('./handlers/invitetoteambycsvAnalyze').handler
app.get  '/-/teams/check-team-invitation'        , require './handlers/teaminvitationchecker'

# used in landing pages where we handle login/register
app.all  '/-/team/:name/members'                 , require './handlers/getteammembers'
app.all  '/-/team/:name'                         , require './handlers/getteam'
app.all  '/-/profile/:email'                     , require './handlers/getprofile'
app.all  '/-/unsubscribe/:token/:email'          , require './handlers/unsubscribe'

# used from client side in site.landing/coffee/core/analytics.coffee
app.post '/-/analytics/track'                    , require './handlers/analytics/track'
app.post '/-/analytics/page'                     , require './handlers/analytics/page'

# used in collaboration
app.get  '/-/google-api/authorize/drive'         , require './handlers/authorizedrive'
app.post '/-/support/new', bodyParser.json()     , require './handlers/supportnew'
app.post '/-/wufoo/submit/:identifier?'          , require './handlers/wufooproxy'

# used in landing
app.post '/-/password-strength'                  , require './handlers/passwordstrength'
app.post '/-/validate/username'                  , require './handlers/validateusername'
app.post '/-/validate/email'                     , require './handlers/validateemail'
app.post '/-/validate'                           , require './handlers/validate'

app.post '/:name?/Register'                      , csrf,   require './handlers/register'
app.post '/:name?/Login'                         , csrf,   require './handlers/login'
app.post '/Impersonate/:nickname'                , csrf,   require './handlers/impersonate'
app.post '/:name?/Recover'                       , csrf,   require './handlers/recover'
app.post '/findteam'                             , csrf,   require './handlers/findteam'
app.post '/:name?/Reset'                         , csrf,   require './handlers/reset'
app.post '/:name?/Optout'                        , require './handlers/optout'
app.all  '/:name?/Logout'                        , csrf,   require './handlers/logout'
app.post '/:name?/Unregister'                    , require './handlers/unregister'
app.get  '/humans.txt'                           , generateHumanstxt
app.get  '/-/healthCheck'                        , require './handlers/healthcheck'
app.get  '/-/versionCheck'                       , require './handlers/versioncheck'
app.get  '/-/version'                            , (req, res) -> res.jsonp { version: KONFIG.version, client_version: KONFIG._CLIENTVERSION }
app.get  '/-/jobs'                               , require './handlers/jobs'
app.post '/recaptcha'                            , require './handlers/recaptcha'
app.get  '/-/presence/:service'                  , (req, res) -> res.status(200).end()
app.post '/-/api/user/create'                    , require './handlers/api/createuser'
app.post '/-/api/ssotoken/create'                , require './handlers/api/createssotoken'
app.get  '/-/api/ssotoken/login'                 , require './handlers/api/ssotokenlogin'
app.get  '/-/api/logs'                           , require './handlers/api/logs'
app.post '/-/api/gitlab', bodyParser.json()      , require './handlers/api/gitlab'
app.get  '/-/image/cache'                        , require './image_cache'
app.get  '/-/oauth/github/callback'              , require './github_callback'
app.get  '/-/oauth/gitlab/callback'              , require './gitlab_callback'

app.post '/-/terraform/document-search' , bodyParser.json(), require './handlers/terraform_doc_search'
app.post '/-/terraform/document-content', bodyParser.json(), require './handlers/terraform_doc_content'

# app.get  '/-/oauth/facebook/callback'            , require './facebook_callback'
# app.get  '/-/oauth/google/callback'              , require './google_callback'
# app.get  '/-/oauth/linkedin/callback'            , require './linkedin_callback'
# app.get  '/-/oauth/twitter/callback'             , require './twitter_callback'
app.post '/:name?/OAuth'                         , require './oauth'
app.get  '/:name?/OAuth/url'                     , require './oauth_url'
app.post '/-/emails/subscribe'                   , (req, res) -> res.status(501).send 'ok'
# should deprecate those /Validates, they don't look like api endpoints
app.post '/Gravatar'                             , require './handlers/gravatar'
app.post '/-/gravatar'                           , require './handlers/gravatar'
app.get  '/-/confirm'                            , require './handlers/confirm'
app.get  '/-/loginwithtoken'                     , require './handlers/loginwithtoken'
app.get  '/:name/:section?/:slug?'               , require './handlers/main.coffee'
app.get  '/-/intercomlauncher'                   , require './handlers/intercomlauncher'
app.get  '*'                                     , require './handlers/root.coffee'

# once bongo is ready we can start listening
koding.once 'dbClientReady', ->

  # start webserver
  app.listen webPort
  console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

  if KONFIG.environment is 'production'
    { NodejsProfiler } = require 'koding-datadog'
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
