zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  boot2dockerbox      = "192.168.59.103"

  hostname            = options.hostname       or "lvh.me:8090"
  publicHostname      = options.publicHostname or process.env.USER
  region              = options.region         or "dev"
  configName          = options.configName     or "dev"
  environment         = options.environment    or "dev"
  projectRoot         = options.projectRoot    or __dirname
  version             = options.version        or "2.0" # TBD
  branch              = options.branch         or "cake-rewrite"
  build               = options.build          or "1111"
  githubuser          = options.githubuser     or "koding"

  mongo               = "#{boot2dockerbox}:27017/koding"
  etcd                = "#{boot2dockerbox}:4001"

  redis               = { host:     "#{boot2dockerbox}"                         , port:               "6379"                                  , db:                 0                         }
  rabbitmq            = { host:     "#{boot2dockerbox}"                         , port:               5672                                    , apiPort:            15672                       , login:           "guest"                              , password: "guest"                     , vhost:         "/"                                    }
  mq                  = { host:     "#{rabbitmq.host}"                          , port:               rabbitmq.port                           , apiAddress:         "#{rabbitmq.host}"          , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"         , componentUser: "#{rabbitmq.login}"                      , password:       "#{rabbitmq.password}"                   , heartbeat:       0           , vhost:        "#{rabbitmq.vhost}" }
  customDomain        = { public:   "http://koding-#{publicHostname}.ngrok.com" , public_:            "koding-#{publicHostname}.ngrok.com"    , local:              "http://lvh.me"             , local_:          "lvh.me"                             , port:     8090                      }
  sendgrid            = { username: "koding"                                    , password:           "DEQl7_Dr"                            }
  email               = { host:     "#{customDomain.public_}"                   , protocol:           'http:'                                 , defaultFromAddress: 'hello@koding.com'          , defaultFromName: 'koding'                             , username: "#{sendgrid.username}"      , password:      "#{sendgrid.password}"                   , templateRoot:   "workers/sitemap/files/"                 , forcedRecipient: undefined }
  kontrol             = { url:      "#{customDomain.public}/kontrol/kite"       , port:               4000                                    , useTLS:             no                          , certFile:        ""                                   , keyFile:  ""                          , publicKeyFile: "./certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "./certs/test_kontrol_rsa_private.pem" }
  broker              = { name:     "broker"                                    , serviceGenericName: "broker"                                , ip:                 ""                          , webProtocol:     "http:"                              , host:     "#{customDomain.public}"    , port:          8008                                     , certFile:       ""                                       , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: "#{customDomain.public}" }
  regions             = { kodingme: "#{configName}"                             , vagrant:            "vagrant"                               , sj:                 "sj"                        , aws:             "aws"                                , premium:  "vagrant"                 }
  algolia             = { appId:    'DYVV81J2S1'                                , apiKey:             '303eb858050b1067bcd704d6cbfb977c'      , indexSuffix:        '.dev'                    }
  algoliaSecret       = { appId:    "#{algolia.appId}"                          , apiKey:             "#{algolia.apiKey}"                     , indexSuffix:        "#{algolia.indexSuffix}"    , apiSecretKey:    '041427512bcdcd0c7bd4899ec8175f46' }
  mixpanel            = { token:    "a57181e216d9f713e19d5ce6d6fb6cb3"          , enabled:            no                                    }
  postgres            = { host:     "#{boot2dockerbox}"                         , port:               5432                                    , username:           "socialapplication"         , password:        "socialapplication"                  , dbname:   "social"                  }

  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go
  socialapi =
    proxyUrl          : "http://localhost:7000"
    configFilePath    : "#{projectRoot}/go/src/socialapi/config/dev.toml"
    postgres          : postgres
    mq                : mq
    redis             :  url: "#{redis.host}:#{redis.port}"
    mongo             : mongo
    environment       : environment
    region            : region
    hostname          : hostname
    email             : email
    sitemap           : { redisDB: 0 }
    algolia           : algoliaSecret
    mixpanel          : mixpanel
    limits            : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: "3" }
    eventExchangeName : "BrokerMessageBus"
    disableCaching    : no
    debug             : yes

  userSitesDomain     = "#{customDomain.public_}"
  socialQueueName     = "koding-social-#{configName}"
  logQueueName        = socialQueueName+'log'

  KONFIG              =
    environment                    : environment
    regions                        : regions
    region                         : region
    hostname                       : hostname
    publicHostname                 : publicHostname
    version                        : version
    broker                         : broker
    uri                            : {address: "#{customDomain.public}"}
    userSitesDomain                : userSitesDomain
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    redis                          : "#{redis.host}:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #

    webserver                      : {port          : 3000                , useCacheHeader: no}
    authWorker                     : {login         : "#{rabbitmq.login}" , queueName : socialQueueName+'auth'     , authExchange      : "auth"                                  , authAllExchange : "authAll"}
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'    , cronDaily : '0 10 0 * * *'             , run               : no                                      , forcedRecipient: email.forcedRecipient                           , maxAge: 3 }
    elasticSearch                  : {host          : "#{boot2dockerbox}" , port      : 9200                       , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                , login     : "#{rabbitmq.login}"        , queueName         : socialQueueName                         , kitePort        : 8765 }
    email                          : email
    newkites                       : {useTLS        : no                  , certFile  : ""                         , keyFile: "#{projectRoot}/kite_home/koding/kite.key"}
    log                            : {login         : "#{rabbitmq.login}" , queueName : logQueueName}
    boxproxy                       : {port          : 8090 }
    sourcemaps                     : {port          : 3526 }
    appsproxy                      : {port          : 3500 }

    kloud                          : {port          : 5500                , privateKeyFile: kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile                        , kontrolUrl: "http://kontrol-#{publicHostname}.ngrok.com/kite"  }
    emailConfirmationCheckerWorker : {enabled: no                         , login : "#{rabbitmq.login}"            , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                                      , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : "4a0b7965feb841238eadf94a46ef72ee"             , loggedRequests: "/^(subscriptions|transactions)/"}
    sendgrid                       : sendgrid
    opsview                        : {push          : no                                             , host          : ''                                           , bin: null                                                                             , conf: null}
    github                         : {clientId      : "f8e440b796d953ea01e5"                         , clientSecret  : "b72e2576926a5d67119d5b440107639c6499ed42"}
    odesk                          : {key           : "639ec9419bc6500a64a2d5c3c29c2cf8"             , secret        : "549b7635e1e4385e"                           , request_url: "https://www.odesk.com/api/auth/v1/oauth/token/request"                  , access_url: "https://www.odesk.com/api/auth/v1/oauth/token/access" , secret_url: "https://www.odesk.com/services/api/auth?oauth_token=" , version: "1.0"                                                    , signature: "HMAC-SHA1" , redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/odesk/callback"}
    facebook                       : {clientId      : "475071279247628"                              , clientSecret  : "65cc36108bb1ac71920dbd4d561aca27"           , redirectUri  : "#{customDomain.host}:#{customDomain.port}/-/oauth/facebook/callback"}
    google                         : {client_id     : "1058622748167.apps.googleusercontent.com"     , client_secret : "vlF2m9wue6JEvsrcAaQ-y9wq"                   , redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/google/callback"}
    twitter                        : {key           : "aFVoHwffzThRszhMo2IQQ"                        , secret        : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E" , redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/twitter/callback"   , request_url  : "https://twitter.com/oauth/request_token"           , access_url   : "https://twitter.com/oauth/access_token"            , secret_url: "https://twitter.com/oauth/authenticate?oauth_token=" , version: "1.0"         , signature: "HMAC-SHA1"}
    linkedin                       : {client_id     : "f4xbuwft59ui"                                 , client_secret : "fBWSPkARTnxdfomg"                           , redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/linkedin/callback"}
    slack                          : {token         : "xoxp-2155583316-2155760004-2158149487-a72cf4" , channel       : "C024LG80K"}
    statsd                         : {use           : false                                          , ip            : "#{customDomain.host}"                       , port: 8125}
    graphite                       : {use           : false                                          , host          : "#{customDomain.host}"                       , port: 2003}
    sessionCookie                  : {maxAge        : 1000 * 60 * 60 * 24 * 14                       , secure        : no}
    logLevel                       : {neo4jfeeder   : "notice"                                       , oskite: "info"                                               , terminal: "info"                                                                      , kontrolproxy  : "notice"                                           , kontroldaemon : "notice"                                           , userpresence  : "notice"                                          , vmproxy: "notice"      , graphitefeeder: "notice"                                                           , sync: "notice" , topicModifier : "notice" , postModifier  : "notice" , router: "notice" , rerouting: "notice" , overview: "notice" , amqputil: "notice" , rabbitMQ: "notice" , ldapserver: "notice" , broker: "notice"}
    aws                            : {key           : "AKIAJSUVKX6PD254UGAA"                         , secret        : "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"}
    embedly                        : {apiKey        : "94991069fb354d4e8fdb825e52d4134a" }
    troubleshoot                   : {recipientEmail: "can@koding.com" }
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    mixpanel                       : mixpanel.token

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client                         : {watch: yes , version       : version , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  KONFIG.client.runtimeOptions =
    kites             : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia           : algolia
    logToExternal     : no                                 # rollbar                                            , mixpanel etc.
    suppressLogs      : no
    logToInternal     : no                                 # log worker
    authExchange      : "auth"
    environment       : environment                        # this is where browser knows what kite environment to query for
    version           : version
    resourceName      : socialQueueName
    userSitesDomain   : userSitesDomain
    logResourceName   : logQueueName
    socialApiUri      : "/xhr"
    apiUri            : "/"
    mainUri           : "/"
    sourceMapsUri     : "/sourcemaps"
    broker            : uri  : "/subscribe"
    appsUri           : "/appsproxy"
    uploadsUri        : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout  : 1000 * 15
    userIdleMs        : 1000 * 60 * 5
    embedly           : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    github            : {clientId     : "f8e440b796d953ea01e5" }
    newkontrol        : {url          : "#{kontrol.url}"}
    sessionCookie     : {maxAge       : 1000 * 60 * 60 * 24 * 14 , secure: no   }
    troubleshoot      : {idleTime     : 1000 * 60 * 60           , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
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


  # THESE COMMANDS WILL EXECUTE IN PARALLEL.

  KONFIG.workers =
    kontrol             : command : "#{GOBIN}/rerun koding/kites/kontrol -c #{configName} -r #{region} -m #{etcd}"
    kloud               : command : "#{GOBIN}/kloud                      -c #{configName} -r #{region} -env dev -port #{KONFIG.kloud.port} -public-key #{kontrol.publicKeyFile} -private-key #{kontrol.privateKeyFile} -kontrol-url #{kontrol.url}  -register-url #{KONFIG.kloud.registerUrl}"
    broker              : command : "#{GOBIN}/rerun koding/broker        -c #{configName}"
    rerouting           : command : "#{GOBIN}/rerun koding/rerouting     -c #{configName}"
    reverseProxy        : command : "#{GOBIN}/reverseproxy               -port 1234 -env production -region #{publicHostname}PublicEnvironment -publicHost proxy-#{publicHostname}.ngrok.com -publicPort 80"

    socialapi           : command : "cd #{projectRoot}/go/src/socialapi && make develop -j config=#{socialapi.configFilePath} && cd #{projectRoot}"

    authworker          : command : "./watch-node #{projectRoot}/workers/auth/index.js               -c #{configName} --disable-newrelic"
    sourcemaps          : command : "./watch-node #{projectRoot}/servers/sourcemaps/index.js         -c #{configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"
    emailsender         : command : "./watch-node #{projectRoot}/workers/emailsender/index.js        -c #{configName} --disable-newrelic"
    appsproxy           : command : "./watch-node #{projectRoot}/servers/appsproxy/web.js            -c #{configName} -p #{KONFIG.appsproxy.port} --disable-newrelic"
    webserver           : command : "./watch-node #{projectRoot}/servers/index.js                    -c #{configName} -p #{KONFIG.webserver.port}   --disable-newrelic"
    socialworker        : command : "./watch-node #{projectRoot}/workers/social/index.js             -c #{configName} -p #{KONFIG.social.port} -r #{region} --disable-newrelic --kite-port=13020"

    clientWatcher       : command : "ulimit -n 1024 && coffee #{projectRoot}/build-client.coffee    --watch --sourceMapsUri /sourcemaps --verbose true"
    ngrokProxy          : command : "coffee #{projectRoot}/ngrokProxy --user #{publicHostname}"
    guestCleaner        : command : "#{GOBIN}/rerun koding/workers/guestcleanerworker -c #{configName}"



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

  nginxConf = """

    worker_processes  1;

    #error_log  logs/error.log;
    #error_log  logs/error.log  notice;
    #error_log  logs/error.log  info;

    #pid        logs/nginx.pid;



    events {
        worker_connections  1024;
    }
    http {
    upstream webs       { server 127.0.0.1:#{KONFIG.webserver.port}  ;}
    upstream social     { server 127.0.0.1:#{KONFIG.social.port}     ;}
    upstream subscribe  { server 127.0.0.1:#{KONFIG.broker.port}     ;}
    upstream kloud      { server 127.0.0.1:#{KONFIG.kloud.port}      ;}
    upstream kontrol    { server 127.0.0.1:#{KONFIG.kontrol.port}    ;}
    upstream appsproxy  { server 127.0.0.1:#{KONFIG.appsproxy.port}  ;}
    upstream sourcemaps { server 127.0.0.1:#{KONFIG.sourcemaps.port} ;}

    map $http_upgrade $connection_upgrade { default upgrade; '' close; }

    gzip on;
    gzip_disable "msie6";

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    server {
      listen 8090 default_server;
      listen [::]:8090 default_server ipv6only=on;

      root /usr/share/nginx/html;
      index index.html index.htm;

      # Make site accessible from http://localhost/
      server_name localhost;

      server_name #{hostname};
      location / {
        proxy_pass            http://webs;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /xhr {
        proxy_pass            http://social;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /appsproxy {
        proxy_pass            http://appsproxy;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /sourcemaps {
        proxy_pass            http://sourcemaps;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }


      location ~^/kloud/.* {
        proxy_pass            http://kloud;
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location ~^/kontrol/.* {
        proxy_pass            http://kontrol;
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }


      location ~^/subscribe/.* {
        proxy_pass http://subscribe;

        proxy_http_version 1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /websocket {
        proxy_pass http://subscribe;

        proxy_http_version 1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }
    }
  }
  """
  fs.writeFileSync "./.dev.nginx.conf",nginxConf

  generateRunFile = (KONFIG) ->

    killlist = ->
      str = "kill -KILL "
      str += "$#{key}pid " for key,val of KONFIG.workers
      str += " $$" #kill self

      return str

    envvars = (options={})->
      options.exclude or= []

      env = """
      export GOPATH=#{projectRoot}/go
      export GOBIN=#{projectRoot}/go/bin
      export KONFIG_JSON='#{KONFIG.JSON}'

      """
      env += "export #{key}='#{val}'\n" for key,val of KONFIG.ENV when key not in options.exclude
      return env

    workerList = (separator=" ")->
      (key for key,val of KONFIG.workers).join separator

    workersRunList = ->
      workers = ""
      for key,val of KONFIG.workers

        workers += """

        function worker_daemon_#{key} {

          #------------- worker: #{key} -------------#
          #{val.command} &>#{projectRoot}/.logs/#{key}.log &
          #{key}pid=$!
          echo [#{key}] started with pid: $#{key}pid


        }

        function worker_#{key} {

          #------------- worker: #{key} -------------#
          #{val.command}

        }

        """
      return workers

    installScript = """

        echo '#---> BUILDING CLIENT (@gokmen) <---#'
        cd #{projectRoot}
        chmod +x ./build-client.coffee
        ulimit -n 1024 && #{projectRoot}/build-client.coffee --watch false  --verbose
        git submodule init
        git submodule update

        # Disabled for now, if any of installed globally with sudo
        # this overrides them and broke developers machine ~
        # npm i gulp stylus coffee-script -g --silent

        npm i --unsafe-perm --silent



        echo '#---> BUILDING GO WORKERS (@farslan) <---#'
        #{projectRoot}/go/build.sh

        echo '#---> BUILDING SOCIALAPI (@cihangir) <---#'
        cd #{projectRoot}/go/src/socialapi
        make configure
        # make install
        cd #{projectRoot}

        echo '#---> AUTHORIZING THIS COMPUTER WITH MATCHING KITE.KEY (@farslan) <---#'
        mkdir $HOME/.kite &>/dev/null
        echo copying #{KONFIG.newkites.keyFile} to $HOME/.kite/kite.key
        cp -f #{KONFIG.newkites.keyFile} $HOME/.kite/kite.key

        echo '#---> BUILDING BROKER-CLIENT @chris <---#'
        echo "building koding-broker-client."
        cd #{projectRoot}/node_modules_koding/koding-broker-client
        cake build
        cd #{projectRoot}


        echo
        echo
        echo 'ALL DONE. Enjoy! :)'
        echo
        echo
    """

    run = """
      #!/bin/bash

      # ------ THIS FILE IS AUTO-GENERATED ON EACH BUILD ----- #\n
      mkdir #{projectRoot}/.logs &>/dev/null

      SERVICES="mongo redis postgres rabbitmq etcd"

      #{envvars()}

      trap ctrl_c INT

      function ctrl_c () {
        echo "ctrl_c detected. killing all processes..."
        kill_all
      }

      function kill_all () {
        rm -rf #{projectRoot}/.logs
        #{killlist()}
        nginx -s quit
        ps aux | grep koding | grep -E 'node|go/bin' | awk '{ print $2 }' | xargs kill -9
      }


      nginxrun () {

        echo "starting nginx"
        nginx -s quit
        nginx -c #{projectRoot}/.dev.nginx.conf


      }

      function printconfig () {
        if [ "$2" == "" ]; then
          cat << EOF
          #{envvars(exclude:["KONFIG_JSON"])}EOF
        elif [ "$2" == "--json" ]; then

          echo '#{KONFIG.JSON}'

        else
          echo ""
        fi

      }

      function run () {
        check
        #{projectRoot}/go/build.sh
        cd #{projectRoot}/go/src/socialapi
        make configure
        cd #{projectRoot}

        nginxrun

        #{("worker_daemon_"+key+"\n" for key,val of KONFIG.workers).join(" ")}

        tail -fq ./.logs/*.log

      }

      #{workersRunList()}


      function printHelp (){

        echo "Usage: "
        echo ""
        echo "  run                    : to start koding"
        echo "  run killall            : to kill every process started by run script"
        echo "  run install            : to compile/install client and "
        echo "  run buildclient        : to see of specified worker logs only"
        echo "  run logs               : to see all workers logs"
        echo "  run log [worker]       : to see of specified worker logs only"
        echo "  run buildservices      : to initialize and start services"
        echo "  run services           : to stop and restart services"
        echo "  run worker             : to list workers"
        echo "  run printconfig        : to print koding config environment variables (output in json via --json flag)"
        echo "  run worker [worker]    : to run a single worker"
        echo "  run help               : to show this list"
        echo ""

      }

      function check (){

        check_service_dependencies

        if [ -z "$DOCKER_HOST" ]; then
          echo "You need to export DOCKER_HOST, run 'boot2docker up' and follow the instructions."
          exit 1
        fi

        mongo #{mongo} --eval "db.stats()"  # do a simple harmless command of some sort

        RESULT=$?   # returns 0 if mongo eval succeeds

        if [ $RESULT -ne 0 ]; then
            echo "cant talk to mongodb at #{mongo}, is it not running? exiting."
            exit 1
        else
            echo "mongodb running!"
        fi


      }

      function check_service_dependencies () {
        echo "checking required services: nginx, docker, mongo..."
        command -v go           >/dev/null 2>&1 || { echo >&2 "I require go but it's not installed.  Aborting."; exit 1; }
        command -v docker       >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
        command -v nginx        >/dev/null 2>&1 || { echo >&2 "I require nginx but it's not installed. (brew install nginx maybe?)  Aborting."; exit 1; }
        command -v boot2docker  >/dev/null 2>&1 || { echo >&2 "I require boot2docker but it's not installed.  Aborting."; exit 1; }
        command -v mongorestore >/dev/null 2>&1 || { echo >&2 "I require mongorestore but it's not installed.  Aborting."; exit 1; }
        command -v node         >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed.  Aborting."; exit 1; }
        command -v npm          >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }

      }

      function build_services () {

        boot2docker up

        echo "Stopping services: $SERVICES"
        docker stop $SERVICES

        echo "Removing services: $SERVICES"
        docker rm   $SERVICES

        # Build Mongo service
        cd #{projectRoot}/install/docker-mongo
        docker build -t koding_localbuild/mongo .

        # Build rabbitMQ service
        cd #{projectRoot}/install/docker-rabbitmq
        docker build -t koding_localbuild/rabbitmq .

        # Build postgres
        cd #{projectRoot}/go/src/socialapi/db/sql
        docker build -t koding_localbuild/postgres .

        docker run -d -p 27017:27017              --name=mongo    koding_localbuild/mongo --dbpath /data/db --smallfiles --nojournal
        docker run -d -p 5672:5672 -p 15672:15672 --name=rabbitmq koding_localbuild/rabbitmq

        docker run -d -p 6379:6379                --name=redis    redis
        docker run -d -p 5432:5432                --name=postgres koding_localbuild/postgres
        docker run -d -p 4001:4001 -p 7001:7001   --name=etcd     coreos/etcd -peer-addr #{boot2dockerbox}:7001 -addr #{boot2dockerbox}:4001

        echo '#---> UPDATING MONGO DATABASE ACCORDING TO LATEST CHANGES IN CODE (UPDATE PERMISSIONS @chris) <---#'
        cd #{projectRoot}
        node #{projectRoot}/scripts/permission-updater  -c #{socialapi.configFilePath} --hard >/dev/null

        echo '#---> UPDATING MONGO DB TO WORK WITH SOCIALAPI @cihangir <---#'
        mongo #{mongo} --eval='db.jAccounts.update({},{$unset:{socialApiId:0}},{multi:true}); db.jGroups.update({},{$unset:{socialApiChannelId:0}},{multi:true});'

        echo '#---> CREATING VANILLA KODING DB @gokmen <---#'

        cd #{projectRoot}/install/docker-mongo
        tar jxvf #{projectRoot}/install/docker-mongo/default-db-dump.tar.bz2
        mongorestore -h#{boot2dockerbox} -dkoding dump/koding
        rm -rf ./dump

      }

      function services () {

        boot2docker up
        EXISTS=$(docker inspect --format="{{ .State.Running }}" $SERVICES 2> /dev/null)
        if [ $? -eq 1 ]; then
          echo ""
          echo "Some of containers are missing, please do ./run buildservices"
          exit 1
        fi

        echo "Stopping services: $SERVICES"
        docker stop $SERVICES

        echo "Starting services: $SERVICES"
        docker start $SERVICES

        echo "starting nginx"
        nginx -s quit
        nginx -c `pwd`/.dev.nginx.conf

      }



      if [[ "$1" == "killall" ]]; then

        kill_all

      elif [ "$1" == "install" ]; then

        #{installScript}

      elif [ "$1" == "printconfig" ]; then

        printconfig $@

      elif [[ "$1" == "log" || "$1" == "logs" ]]; then

        if [ "$2" == "" ]; then
          tail -fq ./.logs/*.log
        else
          tail -fq ./.logs/$2.log
        fi

      elif [ "$1" == "cleanup" ]; then

        ./cleanup $@

      elif [ "$1" == "buildclient" ]; then

        ./build-client.coffee --watch false  --verbose

      elif [ "$1" == "services" ]; then
        check_service_dependencies
        services

      elif [ "$1" == "buildservices" ]; then
        check_service_dependencies

        read -p "This will destroy existing images, do you want to continue? (y/N)" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
            exit 1
        fi

        build_services

      elif [ "$1" == "help" ]; then
        printHelp

      elif [ "$1" == "worker" ]; then

        if [ "$2" == "" ]; then
          echo Available workers:
          echo "-------------------"
          echo '#{workerList "\n"}'
        else
          eval "worker_$2"
        fi

      elif [ "$#" == "0" ]; then

        run

      else
        echo "Unknown command: $1"
        printHelp

      fi
      # ------ THIS FILE IS AUTO-GENERATED BY ./configure ----- #\n
      """
    return run

  KONFIG.ENV            = generateEnvVariables   KONFIG
  KONFIG.supervisorConf = generateSupervisorConf KONFIG
  KONFIG.runFile        = generateRunFile        KONFIG


  return KONFIG

module.exports = Configuration
