prod_simulation_server = "192.168.59.103"

fs                  = require 'fs'
nodePath            = require 'path'
deepFreeze          = require 'koding-deep-freeze'
hat                 = require 'hat'
{argv}              = require 'optimist'
path                = require 'path'
traverse            = require 'traverse'
BLD                 = process.env['KODING_BUILD_DATA_PATH'] or path.join __dirname,"../install/BUILD_DATA"

hostname            = (fs.readFileSync BLD+"/BUILD_HOSTNAME"        , 'utf8').replace("\n","")
publicHostname      = (fs.readFileSync BLD+"/BUILD_PUBLIC_HOSTNAME" , 'utf8').replace("\n","")
region              = (fs.readFileSync BLD+"/BUILD_REGION"          , 'utf8').replace("\n","")
configName          = (fs.readFileSync BLD+"/BUILD_CONFIG"          , 'utf8').replace("\n","")
environment         = (fs.readFileSync BLD+"/BUILD_ENVIRONMENT"     , 'utf8').replace("\n","")
projectRoot         = (fs.readFileSync BLD+"/BUILD_PROJECT_ROOT"    , 'utf8').replace("\n","")
version             = (fs.readFileSync BLD+"/BUILD_VERSION"         , 'utf8').replace("\n","")

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
  url               : "http://127.0.0.1:4000/kite"
  port              : 4000
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
  publicHostname    : publicHostname
  version           : version
  broker            : broker
  uri               : {address: "#{customDomain.public}:#{customDomain.port}"}
  userSitesDomain   : userSitesDomain
  projectRoot       : projectRoot
  socialapi         : socialapi        # THIS IS WHERE WEBSERVER & SOCIAL WORKER KNOW HOW TO CONNECT TO SOCIALAPI
  mongo             : mongo
  redis             : "#{redis.host}:#{redis.port}"
  misc              : {claimGlobalNamesForUsers: no, updateAllSlugs : no, debugConnectionErrors: yes}

  # -- WORKER CONFIGURATION -- #

  presence          : {exchange      : 'services-presence'}
  webserver         : {port          : 3000                        , useCacheHeader: no}
  authWorker        : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth', authExchange      : "auth"             , authAllExchange : "authAll"}
  mq                : {host          : "#{rabbitmq.host}"          , port      : rabbitmq.port         , apiAddress        : "#{rabbitmq.host}" , apiPort         : "#{rabbitmq.apiPort}", login:"#{rabbitmq.login}",componentUser:"#{rabbitmq.login}",password: "#{rabbitmq.password}",heartbeat: 0, vhost: "#{rabbitmq.vhost}"}
  emailWorker       : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'        , run               : no                 , forcedRecipient : undefined, maxAge: 3}
  elasticSearch     : {host          : "#{prod_simulation_server}" , port      : 9200                  , enabled           : no                 , queue           : "elasticSearchFeederQueue"}
  social            : {port          : 3030                        , login     : "#{rabbitmq.login}"   , queueName         : socialQueueName    , kitePort        : 8765 }
  email             : {host          : "#{customDomain.public}"    , protocol  : 'http:'               , defaultFromAddress: 'hello@koding.com' }
  newkites          : {useTLS        : no                          , certFile  : ""                    , keyFile: "#{projectRoot}/kite_home/koding/kite.key"}
  log               : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}
  boxproxy          : {port          : 8090 }
  sourcemaps        : {port          : 3526 }
  kloud             : {port          : 5500, privateKeyFile: kontrol.privateKeyFile, publicKeyFile: kontrol.publicKeyFile, kontrolUrl: "http://kontrol-#{publicHostname}.ngrok.com/kite"  }
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

  client            : {watch: yes, version       : version, includesPath:'client', indexMaster: "index-master.html", index: "default.html", useStaticFileServer: no, staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

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
  sourceMapsUri     : "#{customDomain.public}/sourcemaps"
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
GOBIN = "#{projectRoot}/go/bin"


# THESE COMMANDS WILL EXECUTE SEQUENTIALLY.
KONFIG.workers =
  rerouting           : command : "#{GOBIN}/rerouting          -c #{configName}"
  cron                : command : "#{GOBIN}/cron               -c #{configName}"
  broker              : command : "#{GOBIN}/broker             -c #{configName}"
  socialapi           : command : "#{GOBIN}/api                -c #{socialapi.configFilePath} -port #{socialapi.port}"
  dailyemailnotifier  : command : "#{GOBIN}/dailyemailnotifier -c #{socialapi.configFilePath}"
  notification        : command : "#{GOBIN}/notification       -c #{socialapi.configFilePath}"
  popularpost         : command : "#{GOBIN}/popularpost        -c #{socialapi.configFilePath}"
  populartopic        : command : "#{GOBIN}/populartopic       -c #{socialapi.configFilePath}"
  realtime            : command : "#{GOBIN}/realtime           -c #{socialapi.configFilePath}"
  sitemapfeeder       : command : "#{GOBIN}/sitemapfeeder      -c #{socialapi.configFilePath}"
  topicfeed           : command : "#{GOBIN}/topicfeed          -c #{socialapi.configFilePath}"
  trollmode           : command : "#{GOBIN}/trollmode          -c #{socialapi.configFilePath}"
  webserver           : command : "node   #{projectRoot}/server/index.js                   -c #{configName} -p #{KONFIG.webserver.port}   --disable-newrelic"
  socialworker        : command : "node   #{projectRoot}/workers/social/index.js           -c #{configName} -p #{KONFIG.social.port}      -r #{region} --disable-newrelic --kite-port=13020"
  sourcemaps          : command : "node   #{projectRoot}/server/lib/source-server/index.js -c #{configName} -p #{KONFIG.sourcemaps.port}"
  authworker          : command : "node   #{projectRoot}/workers/auth/index.js             -c #{configName}"
  emailsender         : command : "node   #{projectRoot}/workers/emailsender/index.js      -c #{configName}"
  boxproxy            : command : "node #{projectRoot}/server/boxproxy.js            -c #{configName}"
  clientWatcher       : command : "coffee #{projectRoot}/build-client.coffee               --watch --sourceMapsUri #{hostname}"
  kontrol             : command : "#{GOBIN}/kontrol -c #{configName} -r #{region}"
  kloud               : command : "#{GOBIN}/kloud -c #{configName} -r #{region} -port #{KONFIG.kloud.port} -public-key #{KONFIG.kloud.publicKeyFile} -private-key #{KONFIG.kloud.privateKeyFile} -kontrol-url \"#{KONFIG.kloud.kontrolUrl}\" -debug"

  # guestcleaner        : command : "node #{projectRoot}/workers/guestcleaner/index.js     -c #{configName}"


KONFIG.workers =
  # dailyemailnotifier  : command : "#{GOBIN}/dailyemailnotifier -c #{socialapi.configFilePath}"
  # notification        : command : "#{GOBIN}/notification       -c #{socialapi.configFilePath}"
  # popularpost         : command : "#{GOBIN}/popularpost        -c #{socialapi.configFilePath}"
  # populartopic        : command : "#{GOBIN}/populartopic       -c #{socialapi.configFilePath}"
  # realtime            : command : "#{GOBIN}/realtime           -c #{socialapi.configFilePath}"
  # sitemapfeeder       : command : "#{GOBIN}/sitemapfeeder      -c #{socialapi.configFilePath}"
  # topicfeed           : command : "#{GOBIN}/topicfeed          -c #{socialapi.configFilePath}"
  # trollmode           : command : "#{GOBIN}/trollmode          -c #{socialapi.configFilePath}"
  kloud               : command : "#{GOBIN}/rerun koding/kites/kloud     -c #{configName} -r #{region} -port #{KONFIG.kloud.port} -public-key #{KONFIG.kloud.publicKeyFile} -private-key #{KONFIG.kloud.privateKeyFile} -kontrol-url \"http://#{KONFIG.kloud.kontrolUrl}\" -debug"
  kontrol             : command : "#{GOBIN}/rerun koding/kites/kontrol   -c #{configName} -r #{region}"
  broker              : command : "#{GOBIN}/rerun koding/broker          -c #{configName}"
  rerouting           : command : "#{GOBIN}/rerun koding/rerouting       -c #{configName}"
  cron                : command : "#{GOBIN}/rerun koding/cron            -c #{configName}"
  reverseProxy        : command : "#{GOBIN}/rerun koding/kites/reverseproxy -port 1234 -env production -region #{publicHostname}PublicEnvironment -publicHost proxy-#{publicHostname}.ngrok.com -publicPort 80"

  socialapi           : command : "cd go/src/socialapi && make develop -j config=#{socialapi.configFilePath}"

  webserver           : command : "cd #{projectRoot}/servers/lib/server/        && nodemon index.coffee  --webserver    -c #{configName} -p #{KONFIG.webserver.port}   --disable-newrelic"
  socialworker        : command : "cd #{projectRoot}/workers/social/lib/social/ && nodemon main.coffee   --socialworker -c #{configName} -p #{KONFIG.social.port}      -r #{region} --disable-newrelic --kite-port=13020"
  sourcemaps          : command : "cd #{projectRoot}/servers/lib/source-server/ && nodemon main.coffee   --sourcemaps   -c #{configName} -p #{KONFIG.sourcemaps.port}"
  boxproxy            : command : "cd #{projectRoot}/servers/boxproxy/          && nodemon boxproxy.js   --boxproxy     -c #{configName}"
  authworker          : command : "cd #{projectRoot}/workers/auth/lib/auth/     && nodemon main.coffee   --authWorker   -c #{configName}"
  emailsender         : command : "cd #{projectRoot}/workers/emailsender/       && nodemon main.coffee   --emailsender  -c #{configName}"

  clientWatcher       : command : "coffee #{projectRoot}/build-client.coffee    --watch --sourceMapsUri #{hostname}"

  ngrokProxy          : command : "#{projectRoot}/ngrokProxy --user #{publicHostname}"

  # --port #{kontrol.port} -env #{environment} -public-key #{kontrol.publicKeyFile} -private-key #{kontrol.privateKeyFile}"
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
    str += " $$" #kill self

    return str

  envvars = ->
    env = """
    export GOPATH=#{projectRoot}/go
    export GOBIN=#{projectRoot}/go/bin
    """
    env += "export #{key}='#{val}'\n" for key,val of KONFIG.ENV
    return env

  workersRunList = ->
    workers = ""
    for key,val of KONFIG.workers
      workers +="#------------- worker: #{key} -------------#\n"
      workers +="#{val.command} &>#{projectRoot}/.logs/#{key}.log & \n"
      workers +="#{key}pid=$! \n"
      workers +="echo [#{key}] started with pid: $#{key}pid \n\n"
    return workers

  run = """
    #/bin/bash
    # ------ THIS FILE IS AUTO-GENERATED ON EACH BUILD ----- #\n
    mkdir .logs &>/dev/null

    #{envvars()}

    trap ctrl_c INT

    function ctrl_c () {
      echo "ctrl_c detected. killing all processes..."
      kill_all
    }

    watch() {

    echo watching folder $1/ every $2 secs.

    while [[ true ]]
    do
        files=`find $1 -type f -mtime -$2s`
        if [[ $files != "" ]] ; then
            echo changed, $files
        fi
        sleep $2
    done
    }

    function kill_all () {
    #{killlist()}
    }
    if [[ "$1" == "" ]]; then

      #{workersRunList()}

      tail -fq ./.logs/*.log

    elif [ "$1" == "killall" ]; then

      kill_all

    elif [ "$1" == "install" ]; then

      echo '#---> BUILDING CLIENT (@gokmen) <---#'
      cd #{projectRoot}
      chmod +x ./build-client.coffee
      NO_UGLIFYJS=true ./build-client.coffee --watch false  --verbose
      git submodule init
      git submodule update
      npm i gulp stylus coffee-script nodemon -g --silent
      npm i --unsafe-perm --silent



      echo '#---> BUILDING GO WORKERS (@farslan) <---#'
      #{projectRoot}/go/build.sh

      echo '#---> BUILDING SOCIALAPI (@cihangir) <---#'
      cd #{projectRoot}/go/src/socialapi
      make configure
      make install

      echo '#---> AUTHORIZING THIS COMPUTER WITH MATCHING KITE.KEY (@farslan) <---#'
      mkdir $HOME/.kite &>/dev/null
      echo copying #{KONFIG.newkites.keyFile} to $HOME/.kite/kite.key
      cp #{KONFIG.newkites.keyFile} $HOME/.kite/kite.key

      echo '#---> BUILDING BROKER-CLIENT @chris <---#'
      echo "building koding-broker-client."
      cd #{projectRoot}/node_modules_koding/koding-broker-client
      cake build


      echo '#---> AUTHORIZING THIS COMPUTER TO DOCKER HUB (@devrim) <---#'
      echo adding you to docker-hub..
      if grep -q ZGV2cmltOm45czQvV2UuTWRqZWNq "$HOME/.dockercfg"; then
        echo 'you seem to have correct docker config file - dont forget to install docker.'
      else
        echo 'added ~/.dockercfg - dont forget to install docker.'
        echo '{"https://index.docker.io/v1/":{"auth":"ZGV2cmltOm45czQvV2UuTWRqZWNq","email":"devrim@koding.com"}}' >> $HOME/.dockercfg
      fi


      echo '#---> AUTHORIZING THIS COMPUTER TO NGROK (@gokmen) <---#'
      if grep -q UsZMWdx586A3tA0U "$HOME/.ngrok"; then
        echo you seem to have correct .ngrok file.
      else
        echo 'created ~/.ngrok file (you may still need to download the client)'
        echo auth_token: CMY-UsZMWdx586A3tA0U >> $HOME/.ngrok
      fi


      echo
      echo
      echo 'ALL DONE. Enjoy! :)'
      echo
      echo


    elif [ "$1" == "log" ]; then

      if [ "$2" == "" ]; then
        tail -fq ./.logs/*.log
      else
        tail -fq ./.logs/$2.log
      fi

    elif [ "$1" == "cleanup" ]; then

      ./cleanup @$

    elif [ "$1" == "services" ]; then
      docker run -d --net=host --name=mongo    koding/mongo    --dbpath /root/data/db --smallfiles --nojournal
      docker run -d --net=host --name=redis    koding/redis
      docker run -d --net=host --name=postgres koding/postgres
      docker run -d --net=host --name=rabbitmq koding/rabbitmq

      echo '#---> UPDATING MONGO DATABASE ACCORDING TO LATEST CHANGES IN CODE (UPDATE PERMISSIONS @chris) <---#'
      cd #{projectRoot}
      node #{projectRoot}/scripts/permission-updater  -c #{socialapi.configFilePath} --hard >/dev/null

    else
      echo "unknown argument. use ./run [killall]"
    fi
    # ------ THIS FILE IS AUTO-GENERATED BY ./configure ----- #\n
    """
  return run

KONFIG.ENV            = generateEnvVariables   KONFIG
KONFIG.supervisorConf = generateSupervisorConf KONFIG
KONFIG.runFile        = generateRunFile        KONFIG

# console.log KONFIG.runFile

module.exports = KONFIG



