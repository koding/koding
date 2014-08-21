zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  prod_simulation_server = "10.0.0.137"

  hostname            = options.hostname       or "prod-v1_2_4-anna"
  publicHostname      = options.publicHostname or "https://koding.me"
  region              = options.region         or "aws"
  configName          = options.configName     or "sandbox"
  environment         = options.environment    or "sandbox"
  projectRoot         = options.projectRoot    or "/opt/koding"
  version             = options.tag
  tag                 = options.tag
  publicIP            = options.publicIP       or "*"
  githubuser          = options.githubuser     or "koding"

  mongo               = "#{prod_simulation_server}:27017/koding"
  etcd                = "#{prod_simulation_server}:4001"

  redis               = { host:     "#{prod_simulation_server}"              , port:               6379                                  , db:              0                    }
  rabbitmq            = { host:     "#{prod_simulation_server}"              , port:               5672                                  , apiPort:         15672                  , login:           "guest"                              , password: "guest"                , vhost:         "/"                                                 }
  mq                  = { host:     "#{rabbitmq.host}"                       , port:               rabbitmq.port                         , apiAddress:      "#{rabbitmq.host}"     , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"    , componentUser: "#{rabbitmq.login}"                                   , password:       "#{rabbitmq.password}"                                , heartbeat:       0           , vhost:        "#{rabbitmq.vhost}" }
  customDomain        = { public:   "http://#{hostname}"                     , public_:            "#{hostname}"                         , local:           "http://localhost"     , local_:          "localhost"                          , port:     80                   }
  sendgrid            = { username: "koding"                                 , password:           "DEQl7_Dr"                          }
  email               = { host:     "#{customDomain.public_}"                , protocol:           'https:'                              , defaultFromMail: 'hello@koding.com'     , defaultFromName: 'koding'                             , username: sendgrid.username      , password:      sendgrid.password                                     , templateRoot:   "workers/sitemap/files/"                              , forcedRecipient: undefined }
  kontrol             = { url:      "#{customDomain.public}/kontrol/kite"    , port:               4000                                  , useTLS:          no                     , certFile:        ""                                   , keyFile:  ""                     , publicKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_private.pem" }
  broker              = { name:     "broker"                                 , serviceGenericName: "broker"                              , ip:              ""                     , webProtocol:     "http:"                              , host:     customDomain.public    , port:          8008                                                  , certFile:       ""                                                    , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: customDomain.public }
  regions             = { kodingme: "#{configName}"                          , vagrant:            "vagrant"                             , sj:              "sj"                   , aws:             "aws"                                , premium:  "vagrant"            }
  algolia             = { appId:    'DYVV81J2S1'                             , apiKey:             '303eb858050b1067bcd704d6cbfb977c'    , indexSuffix:     '.sandbox'           }
  algoliaSecret       = { appId:    algolia.appId                            , apiKey:             algolia.apiKey                        , indexSuffix:     algolia.indexSuffix    , apiSecretKey:    '041427512bcdcd0c7bd4899ec8175f46' }
  mixpanel            = { token:    "a57181e216d9f713e19d5ce6d6fb6cb3"       , enabled:            no                                  }
  postgres            = { host:     "#{prod_simulation_server}"              , port:               5432                                  , username:        "socialapplication"    , password:        "socialapplication"                  , dbname:   "social"             }

  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go
  socialapi =
    proxyUrl          : "http://localhost:7000"
    configFilePath    : "#{projectRoot}/go/src/socialapi/config/sandbox.toml"
    postgres          : postgres
    mq                : mq
    redis             : url: "#{redis.host}:#{redis.port}"
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
    uri                            : {address: "#{customDomain.public}:#{customDomain.port}"}
    userSitesDomain                : userSitesDomain
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    redis                          : "#{redis.host}:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #

    webserver                      : {port          : 3000                        , useCacheHeader: no}
    authWorker                     : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth'      , authExchange      : "auth"                                  , authAllExchange : "authAll"}
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'              , run               : yes                                     , forcedRecipient : email.forcedRecipient               , maxAge: 3 }
    elasticSearch                  : {host          : "#{prod_simulation_server}" , port      : 9200                        , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                        , login     : "#{rabbitmq.login}"         , queueName         : socialQueueName                         , kitePort        : 8765 }
    email                          : email
    newkites                       : {useTLS        : no                          , certFile  : ""                          , keyFile: "#{projectRoot}/kite_home/sandbox/kite.key"}
    log                            : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}
    boxproxy                       : {port          : 80 }
    sourcemaps                     : {port          : 3526 }
    appsproxy                      : {port          : 3500 }

    kloud                          : {port          : 5500                        , privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile                        , kontrolUrl: "#{kontrol.url}"    , registerUrl: "#{customDomain.public}/kloud/kite"  }
    emailConfirmationCheckerWorker : {enabled: no                                 , login : "#{rabbitmq.login}"             , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                           , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'             , loggedRequests: "/^(subscriptions|transactions)/"}
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
    aws                            : {key           : 'AKIAJSUVKX6PD254UGAA'                         , secret        : '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'}
    embedly                        : {apiKey        : '94991069fb354d4e8fdb825e52d4134a'}
    troubleshoot                   : {recipientEmail: "can@koding.com"}
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    mixpanel                       : mixpanel.token
    recapthcha                     : '6LcF9vgSAAAAAOTEx2iMgeJ5HQSyysPyKzUYPNjF'

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client                         : {watch: yes , version: version , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

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
    appsUri           : "/appsproxy"
    uploadsUri        : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout  : 1000 * 15
    userIdleMs        : 1000 * 60 * 5
    embedly           : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    broker            : {uri          : "/subscribe" }
    github            : {clientId     : "f8e440b796d953ea01e5" }
    newkontrol        : {url          : "#{kontrol.url}"}
    sessionCookie     : {maxAge       : 1000 * 60 * 60 * 24 * 14  , secure: no   }
    troubleshoot      : {idleTime     : 1000 * 60 * 60            , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    recaptcha         : '6LcF9vgSAAAAACeSHac-T9GitKb5ibaBexvnnrVZ'
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
    kontrol             : command : "#{GOBIN}/kontrol -region #{region} -environment #{environment} -mongourl #{mongo} -port #{kontrol.port}      -privatekey #{kontrol.privateKeyFile} -publickey #{kontrol.publicKeyFile} -machines #{etcd}"
    kloud               : command : "#{GOBIN}/kloud   -region #{region} -environment #{environment} -mongourl #{mongo} -port #{KONFIG.kloud.port} -privatekey #{kontrol.privateKeyFile} -publickey #{kontrol.publicKeyFile} -kontrolurl #{kontrol.url} -registerurl #{KONFIG.kloud.registerUrl}"

    broker              : command : "#{GOBIN}/broker    -c #{configName}"
    rerouting           : command : "#{GOBIN}/rerouting -c #{configName}"
    reverseProxy        : command : "#{GOBIN}/reverseproxy               -port 1234 -env production -region #{publicHostname}PublicEnvironment -publicHost proxy-#{publicHostname}.ngrok.com -publicPort 80"

    socialapi           : command : "#{GOBIN}/api                -c #{socialapi.configFilePath}"

    authworker          : command : "coffee #{projectRoot}/workers/auth/lib/auth/main.coffee      -c #{configName}"
    sourcemaps          : command : "coffee #{projectRoot}/servers/sourcemaps/main.coffee         -c #{configName} -p #{KONFIG.sourcemaps.port}"
    emailsender         : command : "coffee #{projectRoot}/workers/emailsender/main.coffee        -c #{configName}"
    appsproxy           : command : "node   #{projectRoot}/servers/appsproxy/web.js               -c #{configName} -p #{KONFIG.appsproxy.port}"
    webserver           : command : "coffee #{projectRoot}/servers/lib/server/index.coffee        -c #{configName} -p #{KONFIG.webserver.port}   --disable-newrelic"
    socialworker        : command : "coffee #{projectRoot}/workers/social/lib/social/main.coffee  -c #{configName} -p #{KONFIG.social.port}      -r #{region} --disable-newrelic --kite-port=13020"


    dailyemailnotifier  : command : "#{GOBIN}/dailyemailnotifier -c #{socialapi.configFilePath}"
    notification        : command : "#{GOBIN}/notification       -c #{socialapi.configFilePath}"
    popularpost         : command : "#{GOBIN}/popularpost        -c #{socialapi.configFilePath}"
    populartopic        : command : "#{GOBIN}/populartopic       -c #{socialapi.configFilePath}"
    pinnedpost          : command : "#{GOBIN}/pinnedpost         -c #{socialapi.configFilePath}"
    realtime            : command : "#{GOBIN}/realtime           -c #{socialapi.configFilePath}"
    sitemapfeeder       : command : "#{GOBIN}/sitemapfeeder      -c #{socialapi.configFilePath}"
    sitemapgenerator    : command : "#{GOBIN}/sitemapgenerator   -c #{socialapi.configFilePath}"
    emailnotifier       : command : "#{GOBIN}/emailnotifier      -c #{socialapi.configFilePath}"
    topicfeed           : command : "#{GOBIN}/topicfeed          -c #{socialapi.configFilePath}"
    trollmode           : command : "#{GOBIN}/trollmode          -c #{socialapi.configFilePath}"


  #-------------------------------------------------------------------------#
  #---- SECTION: AUTO GENERATED CONFIGURATION FILES ------------------------#
  #---- DO NOT CHANGE ANYTHING BELOW. IT'S GENERATED FROM WHAT'S ABOVE  ----#
  #-------------------------------------------------------------------------#

  KONFIG.JSON = JSON.stringify KONFIG

  b64z = (str,strict=yes,compress=yes)->
    if str
      _b64 = new Buffer(str)
      _b64 = zlib.compress _b64 if compress
      # log "[b64z] before #{str.length} after #{_b64.length}"
      return _b64.toString('base64')
    else
      if strict
        throw "base64 STRING is empty, check main.#{configName}.coffee. this will break the prod machine, exiting."
      else
        return ""

  prodKeys =
    id_rsa          : fs.readFileSync( "./install/keys/prod.ssh/id_rsa"          ,"utf8")
    id_rsa_pub      : fs.readFileSync( "./install/keys/prod.ssh/id_rsa.pub"      ,"utf8")
    authorized_keys : fs.readFileSync( "./install/keys/prod.ssh/authorized_keys" ,"utf8")
    config          : fs.readFileSync( "./install/keys/prod.ssh/config"          ,"utf8")

  nginxConf = """
    upstream webs      { server 127.0.0.1:#{KONFIG.webserver.port} ;}
    upstream social    { server 127.0.0.1:#{KONFIG.social.port}    ;}
    upstream subscribe { server 127.0.0.1:#{KONFIG.broker.port}    ;}
    upstream kontrol   { server 127.0.0.1:#{KONFIG.kontrol.port}   ;}
    upstream kloud     { server 127.0.0.1:#{KONFIG.kloud.port}     ;}
    upstream appsproxy { server 127.0.0.1:#{KONFIG.appsproxy.port} ;}

    map $http_upgrade $connection_upgrade { default upgrade; '' close; }

    # TBD ssl_config

    server {
      listen 80 default_server;
      listen [::]:80 default_server ipv6only=on;
      listen 443;

      root /usr/share/nginx/html;
      index index.html index.htm;

      # Make site accessible from http://localhost/
      server_name localhost;


      server_name #{hostname};
      location / {
        auth_basic            "Restricted";
        auth_basic_user_file  /etc/nginx/conf.d/.htpasswd;
        proxy_pass            http://webs;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /xhr {
        proxy_pass            http://social;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /appsproxy {
        proxy_pass            http://appsproxy;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      # TBD. ADD WEBSOCKET SUPPORT HERE

      location ~^/subscribe/.* {
        proxy_pass http://subscribe;

        proxy_http_version 1.1;
        proxy_set_header      Upgrade    $http_upgrade;
        proxy_set_header      Connection "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
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
        proxy_next_upstream   error timeout invalid_header http_500;
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
    }
  """

  generateEnvVariables = (KONFIG)->
    conf = {}
    travis = traverse(KONFIG)
    travis.paths().forEach (path) -> conf["KONFIG_#{path.join("_")}".toUpperCase()] = travis.get(path) unless typeof travis.get(path) is 'object'
    return conf


  generateSupervisorConf = (KONFIG)->
    supervisorEnvironmentStr = "HOME='/root',GOPATH='#{projectRoot}/go',GOBIN='#{projectRoot}/go/bin',KONFIG_JSON='#{KONFIG.JSON}'"
    # supervisorEnvironmentStr += "#{key}='#{val}'," for key,val of KONFIG.ENV
    conf = """
      [supervisord]
      environment=#{supervisorEnvironmentStr}\n
      [inet_http_server]
      port=*:9001\n
      """
    conf +="""
      [program:#{key}]
      command=#{val.command}\n
    """ for key,val of KONFIG.workers
    return conf

  generateRunFile = (KONFIG) ->
    envvars = ->
      env = """
      export GOPATH=#{projectRoot}/go
      export GOBIN=#{projectRoot}/go/bin
      export HOME=/root
      export KONFIG_JSON='#{KONFIG.JSON}'
      \n
      """
      # env += "export #{key}='#{val}'\n" for key,val of KONFIG.ENV
      return env

    workersRunList = ->
      workers = ""
      for key,val of KONFIG.workers
        workers +="#------------- worker: #{key} -------------#\n"
        workers +="#{val.command} &>#{projectRoot}/.logs/#{key}.log & \n"
        workers +="#{key}pid=$! \n"
        workers +="echo [#{key}] started with pid: $#{key}pid \n\n"
      return workers


    runContents = """
      #!/bin/bash
      #{envvars()}

      function install() {
        touch /root/run.install.start

        echo #{b64z prodKeys.id_rsa}          | base64 --decode | gunzip >/root/.ssh/id_rsa
        echo #{b64z prodKeys.id_rsa_pub}      | base64 --decode | gunzip >/root/.ssh/id_rsa.pub
        echo #{b64z prodKeys.authorized_keys} | base64 --decode | gunzip >/root/.ssh/authorized_keys
        echo #{b64z prodKeys.config}          | base64 --decode | gunzip >/root/.ssh/config
        chmod 0600 /root/.ssh/id_rsa

        cd /opt
        git clone --recursive --branch '#{tag}' --depth 1 git@github.com:#{options.githubuser}/koding.git koding

        cd /opt/koding

        # retrieve machine settings from the git tag namely, write nginx and supervisor conf.
        ms=`git tag -l -n1 | grep '#{tag}'`
        ms=${ms##*machine-settings-b64-zip-}  # get the part after the last separator
        echo $ms | base64 --decode | gunzip > #{projectRoot}/machineSettings
        bash #{projectRoot}/machineSettings

        npm i gulp stylus coffee-script -g
        npm i --unsafe-perm
        /usr/local/bin/coffee /opt/koding/build-client.coffee --watch false
        bash #{projectRoot}/go/build.sh
        cd #{projectRoot}/go/src/socialapi
        make install
        cd #{projectRoot}/node_modules_koding/koding-broker-client
        cake build
        mkdir $HOME/.kite
        echo copying #{KONFIG.newkites.keyFile} to $HOME/.kite/kite.key
        cp #{KONFIG.newkites.keyFile} $HOME/.kite/kite.key

        # new relic setup
        echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
        wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
        apt-get update
        apt-get install newrelic-sysmond
        nrsysmond-config --set license_key=aa81e308ad9a0d95cf5a90fec9692c80551e8a68
        /etc/init.d/newrelic-sysmond start


        touch /root/run.install.end
      }

      function services() {
        touch /root/run.services.start
        service nginx restart
        service supervisor restart
        touch /root/run.services.end

      }

      if [[ "$1" == "" ]]; then
        install
        services
        exit 0
      elif [ "$1" == "install" ]; then
        install
      elif [ "$1" == "services" ]; then
        services
      else
        echo "unknown argument."
      fi
      """


    run = """
      #cloud-config

      # this file cannot exceed 16k therefore, i'm placing supervisor and nginxConf
      # into git tag message and reading it from there.
      # tl;dr - keep this small.

      disable_root: false
      hostname : #{hostname}

      packages:
        - mc
        - mosh
        - supervisor
        - golang
        - nodejs
        - npm
        - git
        - graphicsmagick
        - mosh
        - nginx
        - mongodb-clients


      write_files:

        - path: /root/run.b64z
          content : #{b64z runContents}
        - path: /root/run
          permissions: '0755'
        - path: /etc/nginx/conf.d/.htpasswd
          content: koding:$apr1$K17a7D.N$vuaxDfc4kJvHAg7Id43wk1

      runcmd:
        - echo 127.0.0.1 `hostname` >> /etc/hosts
        - curl http://169.254.169.254/latest/meta-data/instance-id >/root/instance-id
        - curl -s https://get.docker.io/ubuntu/ | sudo sh
        - ln -sf /usr/bin/nodejs /usr/bin/node
        - ln -sf /usr/bin/supervisorctl /usr/bin/s
        - cat /root/run.b64z | base64 --decode | gunzip > /root/run
        - /root/run
        - echo "deploy done."



    """

    return run

  machineSettings = """
        \n
        echo '#{b64z nginxConf}'                      | base64 --decode | gunzip >  /etc/nginx/sites-enabled/default;
        echo "nginx configured."
        echo '#{b64z generateSupervisorConf(KONFIG)}' | base64 --decode | gunzip >  /etc/supervisor/conf.d/koding.conf;
        echo "supervisor configured."
  """


  KONFIG.machineSettings = b64z machineSettings
  KONFIG.runFile         = generateRunFile KONFIG

  return KONFIG

module.exports = Configuration
