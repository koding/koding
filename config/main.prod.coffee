prod_simulation_server = "192.168.59.103"

fs                  = require 'fs'
nodePath            = require 'path'
deepFreeze          = require 'koding-deep-freeze'
hat                 = require 'hat'
{argv}              = require 'optimist'
path                = require 'path'
traverse            = require 'traverse'
BLD                 = process.env['KODING_BUILD_DATA_PATH'] or path.join __dirname,"../install/BUILD_DATA"

hostname            = (fs.readFileSync BLD+"/BUILD_HOSTNAME"    , 'utf8').replace("\n","")
region              = (fs.readFileSync BLD+"/BUILD_REGION"      , 'utf8').replace("\n","")
configName          = (fs.readFileSync BLD+"/BUILD_CONFIG"      , 'utf8').replace("\n","")
environment         = (fs.readFileSync BLD+"/BUILD_ENVIRONMENT" , 'utf8').replace("\n","")
projectRoot         = (fs.readFileSync BLD+"/BUILD_PROJECT_ROOT", 'utf8').replace("\n","")
version             = (fs.readFileSync BLD+"/BUILD_VERSION"     , 'utf8').replace("\n","")

mongo               = "#{prod_simulation_server}:27017/koding"
redis               = {host     : "#{prod_simulation_server}"   , port : "6379" }
socialapi           = {proxyUrl : "http://localhost:7000"       , port : 7000 , clusterSize : 5,     configFilePath : "#{projectRoot}/go/src/socialapi/config/prod.toml" }
rabbitmq            = {host     : "#{prod_simulation_server}"   , port : 5672 , apiPort     : 15672, login          : "guest", password : "guest", vhost:"/"}

customDomain        =
  public            : "http://#{hostname}"
  public_           : "#{hostname}"
  local             : "http://localhost"
  local_            : "localhost"
  port              : 80


# KONTROL DEPLOYMENT IS SEPARATED FROM PROD DEPLOY.
kontrol             =
  url               : "https://kontrol.koding.com/kite"
  port              : 443
  useTLS            : no
  certFile          : ""
  keyFile           : ""
  publicKeyFile     : "./certs/test_kontrol_rsa_public.pem"
  privateKeyFile    : "./certs/test_kontrol_rsa_private.pem"


broker              = 
  name              : "broker"
  serviceGenericName: "broker"
  ip                : ""
  webProtocol       : "http:"
  host              : customDomain.public
  port              : 8008
  certFile          : ""
  keyFile           : ""
  authExchange      : "auth"
  authAllExchange   : "authAll"
  failoverUri       : customDomain.public

userSitesDomain     = "#{customDomain.public_}"                 # this is for domain settings on environment backend eg. kd.io

socialQueueName     = "koding-social-#{configName}"
logQueueName        = socialQueueName+'log'

regions             =
  kodingme          : "#{configName}"
  vagrant           : "vagrant"
  sj                : "sj"
  aws               : "aws"
  premium           : "vagrant"



KONFIG              =
  environment       : environment
  regions           : regions
  region            : region
  hostname          : hostname
  version           : version
  broker            : broker
  uri               : {address: "#{customDomain.public}:#{customDomain.port}"}
  userSitesDomain   : userSitesDomain
  projectRoot       : projectRoot
  socialapi         : socialapi                                  # THIS IS WHERE WEBSERVER & SOCIAL WORKER KNOW HOW TO CONNECT TO SOCIALAPI
  mongo             : mongo
  redis             : "#{redis.host}:#{redis.port}"
  misc              : {claimGlobalNamesForUsers: no, updateAllSlugs : no, debugConnectionErrors: yes}

  # -- WORKER CONFIGURATION -- #

  webserver         : {useCacheHeader: no}
  presence          : {exchange      : 'services-presence'}
  authWorker        : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth', authExchange      : "auth"             , authAllExchange : "authAll"}
  mq                : {host          : "#{rabbitmq.host}"          , port      : rabbitmq.port         , apiAddress        : "#{rabbitmq.host}" , apiPort         : "#{rabbitmq.apiPort}", login:"#{rabbitmq.login}",componentUser:"#{rabbitmq.login}",password: "#{rabbitmq.password}",heartbeat: 0, vhost: "#{rabbitmq.vhost}"}
  emailWorker       : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'        , run               : no                 , forcedRecipient : undefined, maxAge: 3}
  elasticSearch     : {host          : "#{prod_simulation_server}" , port      : 9200                  , enabled           : no                 , queue           : "elasticSearchFeederQueue"}
  social            : {port          : 3030                        , login     : "#{rabbitmq.login}"   , queueName         : socialQueueName    , kitePort        : 8765 }
  email             : {host          : "#{customDomain.public}"    , protocol  : 'http:'               , defaultFromAddress: 'hello@koding.com' }
  newkites          : {useTLS        : no                          , certFile  : ""                    , keyFile: ""}
  log               : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}

  emailConfirmationCheckerWorker     : {enabled: no, login : "#{rabbitmq.login}", queueName: socialQueueName+'emailConfirmationCheckerWorker',cronSchedule: '0 * * * * *',usageLimitInMinutes  : 60}

  newkontrol        : kontrol
 
  # -- MISC SERVICES --# 
  recurly           : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'            , loggedRequests: /^(subscriptions|transactions)/}  
  opsview           : {push          : no                                            , host          : '', bin: null, conf: null}
  github            : {clientId      : "f8e440b796d953ea01e5"                        , clientSecret  : "b72e2576926a5d67119d5b440107639c6499ed42"}
  odesk             : {key           : "639ec9419bc6500a64a2d5c3c29c2cf8"            , secret        : "549b7635e1e4385e",request_url: "https://www.odesk.com/api/auth/v1/oauth/token/request",access_url: "https://www.odesk.com/api/auth/v1/oauth/token/access",secret_url: "https://www.odesk.com/services/api/auth?oauth_token=",version: "1.0",signature: "HMAC-SHA1",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/odesk/callback"}
  facebook          : {clientId      : "475071279247628"                             , clientSecret  : "65cc36108bb1ac71920dbd4d561aca27", redirectUri  : "#{customDomain.host}:#{customDomain.port}/-/oauth/facebook/callback"}
  google            : {client_id     : "1058622748167.apps.googleusercontent.com"    , client_secret : "vlF2m9wue6JEvsrcAaQ-y9wq",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/google/callback"}
  twitter           : {key           : "aFVoHwffzThRszhMo2IQQ"                       , secret        : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/twitter/callback",    request_url  : "https://twitter.com/oauth/request_token",    access_url   : "https://twitter.com/oauth/access_token",secret_url: "https://twitter.com/oauth/authenticate?oauth_token=",version: "1.0",signature: "HMAC-SHA1"}
  linkedin          : {client_id     : "f4xbuwft59ui"                                , client_secret : "fBWSPkARTnxdfomg", redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/linkedin/callback"}
  slack             : {token         : "xoxp-2155583316-2155760004-2158149487-a72cf4", channel       : "C024LG80K"}
  statsd            : {use           : false                                         , ip            : "#{customDomain.host}", port: 8125}
  graphite          : {use           : false                                         , host          : "#{customDomain.host}", port: 2003}
  sessionCookie     : {maxAge        : 1000 * 60 * 60 * 24 * 14                      , secure        : no}
  logLevel          : {neo4jfeeder   : "notice", oskite: "info", terminal: "info"    , kontrolproxy  : "notice", kontroldaemon : "notice",userpresence  : "notice", vmproxy: "notice", graphitefeeder: "notice", sync: "notice", topicModifier : "notice",  postModifier  : "notice", router: "notice", rerouting: "notice", overview: "notice", amqputil: "notice",rabbitMQ: "notice",ldapserver: "notice",broker: "notice"}
  aws               : {key           : 'AKIAJSUVKX6PD254UGAA'                        , secret        : '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'}
  embedly           : {apiKey        : '94991069fb354d4e8fdb825e52d4134a'}
  troubleshoot      : {recipientEmail: "can@koding.com"}
  rollbar           : "71c25e4dc728431b88f82bd3e7a600c9"
  mixpanel          : "a57181e216d9f713e19d5ce6d6fb6cb3"
    
  #--- CLIENT-SIDE BUILD CONFIGURATION ---#

  client            : {version       : version, includesPath:'client', indexMaster: "index-master.html", index: "default.html", useStaticFileServer: no, staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

#-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
KONFIG.client.runtimeOptions =                                          
  kites             : require './kites.coffee'           # browser passes this version information to kontrol, so it connects to correct version of the kite.
  logToExternal     : no                                 # rollbar, mixpanel etc.
  suppressLogs      : no
  logToInternal     : no                                 # log worker
  authExchange      : "auth"
  environment       : environment                        # this is where browser knows what kite environment to query for 
  version           : version
  resourceName      : socialQueueName
  userSitesDomain   : userSitesDomain
  logResourceName   : logQueueName
  socialApiUri      : "#{customDomain.public}/xhr"
  logApiUri         : "#{customDomain.public}:4030/xhr"
  apiUri            : "#{customDomain.public}"
  mainUri           : "#{customDomain.public}"
  appsUri           : "https://rest.kd.io"
  uploadsUri        : 'https://koding-uploads.s3.amazonaws.com'
  uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
  sourceUri         : "#{customDomain.local}:3526"
  fileFetchTimeout  : 1000 * 15
  userIdleMs        : 1000 * 60 * 5
  embedly           : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
  broker            : {uri          : "#{customDomain.public}/subscribe" }
  github            : {clientId     : "f8e440b796d953ea01e5" }
  newkontrol        : {url          : "#{kontrol.url}"}
  sessionCookie     : {maxAge       : 1000 * 60 * 60 * 24 * 14, secure: no   }
  troubleshoot      : {idleTime     : 1000 * 60 * 60          , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
  externalProfiles  :
    google          : {nicename: 'Google'  }
    linkedin        : {nicename: 'LinkedIn'}
    twitter         : {nicename: 'Twitter' }
    odesk           : {nicename: 'oDesk'   , urlLocation: 'info.profile_url' }
    facebook        : {nicename: 'Facebook', urlLocation: 'link'             }
    github          : {nicename: 'GitHub'  , urlLocation: 'html_url'         }

    # END: PROPERTIES SHARED WITH BROWSER #


#--- RUNTIME CONFIGURATION: WORKERS AND KITES ---#

KONFIG.workers =
  rerouting           : command : "#{projectRoot}/go/bin/rerouting          -c #{configName}"
  cron                : command : "#{projectRoot}/go/bin/cron               -c #{configName}"
  broker              : command : "#{projectRoot}/go/bin/broker             -c #{configName}"
  socialapi           : command : "#{projectRoot}/go/bin/api                -c #{socialapi.configFilePath} -port #{socialapi.port}"
  dailyemailnotifier  : command : "#{projectRoot}/go/bin/dailyemailnotifier -c #{socialapi.configFilePath}" 
  notification        : command : "#{projectRoot}/go/bin/notification                    -c #{socialapi.configFilePath}"
  popularpost         : command : "#{projectRoot}/go/bin/popularpost                     -c #{socialapi.configFilePath}"
  populartopic        : command : "#{projectRoot}/go/bin/populartopic                    -c #{socialapi.configFilePath}"
  realtime            : command : "#{projectRoot}/go/bin/realtime                        -c #{socialapi.configFilePath}"
  sitemapfeeder       : command : "#{projectRoot}/go/bin/sitemapfeeder                   -c #{socialapi.configFilePath}"
  topicfeed           : command : "#{projectRoot}/go/bin/topicfeed                       -c #{socialapi.configFilePath}"
  trollmode           : command : "#{projectRoot}/go/bin/trollmode                       -c #{socialapi.configFilePath}"
  webserver           : command : "node #{projectRoot}/server/index.js                   -c #{configName} -p 3000   --disable-newrelic"
  authworker          : command : "node #{projectRoot}/workers/auth/index.js             -c #{configName}"
  socialworker        : command : "node #{projectRoot}/workers/social/index.js           -c #{configName} -p 3030 -r #{region} --disable-newrelic --kite-port=13020"
  sourcemaps          : command : "node #{projectRoot}/server/lib/source-server/index.js -c #{configName} -p 3526"
  emailsender         : command : "node #{projectRoot}/workers/emailsender/index.js      -c #{configName}"
  # permissionUpdater   : command : "node #{projectRoot}/scripts/permission-updater             -c #{socialapi.configFilePath} --hard"
  # guestcleaner        : command : "node #{projectRoot}/workers/guestcleaner/index.js     -c #{configName}"






#-------------------------------------------------------------------------#
#---- SECTION: AUTO GENERATED CONFIGURATION FILES ------------------------#
#---- DO NOT CHANGE ANYTHING BELOW. IT'S GENERATED FROM WHAT'S ABOVE  ----#
#-------------------------------------------------------------------------#

KONFIG.JSON = JSON.stringify KONFIG

#---- SUPERVISOR CONFIG ----#

generateEnvVariables = (KONFIG)->
  conf = {}
  travis = traverse(KONFIG)
  travis.paths().forEach (path) -> conf["KONFIG_#{path.join("_")}".toUpperCase()] = travis.get(path) unless typeof travis.get(path) is 'object'
  return conf

generateSupervisorConf = (KONFIG)->
  supervisorEnvironmentStr = ''
  supervisorEnvironmentStr += "#{key}='#{val}'," for key,val of KONFIG.ENV
  conf = """
    [supervisord]
    environment=#{supervisorEnvironmentStr}\n 
    [inet_http_server]
    port=*:9001\n\n"""
  conf +="""
    [program:#{key}]
    command=#{val.command}\n
  """ for key,val of KONFIG.workers
  return conf

generateRunFile = (KONFIG) ->

  killlist = ->
    str = "kill -KILL "
    str += "$#{key}pid " for key,val of KONFIG.workers


    return str

  envvars = ->
    env = ''
    env += "export #{key}='#{val}'\n" for key,val of KONFIG.ENV
    return env

  conf = """
    #/bin/bash
    # ------ THIS FILE IS AUTO-GENERATED ON EACH BUILD ----- #\n
    mkdir .logs &>/dev/null

    #{envvars()}

    trap ctrl_c INT

    function ctrl_c () {
      echo "ctrl_c detected. killing all processes..."
      kill_all
    }

    function kill_all () {
    #{killlist()}      
    }
    if [[ "$1" == "" ]]; then
    \n\n"""

  conf +="""  
          #{val.command} &>./.logs/#{key}.log &
          #{key}pid=$!
          echo [#{key}] started with pid: $#{key}pid
        """ for key,val of KONFIG.workers
  conf += """\n
      tail -fq ./.logs/*.log
      \n
      elif [ "$1" == "killall" ]; then
        kill_all
      """
  conf += """\n      
      elif [ "$1" == "log" ]; then
        if [ "$2" == "" ]; then
          tail -fq ./.logs/*.log
        else
          tail -fq ./.logs/$2.log
        fi\n
      """
  conf +="""
    elif [ "$1" == "services" ]; then
      docker run -d --net=host --name=mongo    koding/mongo    --dbpath /root/data/db --smallfiles --nojournal
      docker run -d --net=host --name=redis    koding/redis    redis-server 
      docker run -d --net=host --name=postgres koding/postgres 
      docker run -d --net=host --name=rabbitmq koding/rabbitmq\n
      """
  conf += """\n
      else
        echo "unknown argument. use ./run [killall]"
      fi
      # ------ THIS FILE IS AUTO-GENERATED ON EACH BUILD ----- #\n
      """
  return conf

KONFIG.ENV            = generateEnvVariables   KONFIG
KONFIG.supervisorConf = generateSupervisorConf KONFIG
KONFIG.runFile        = generateRunFile        KONFIG

# console.log KONFIG.runFile

module.exports = KONFIG



