traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'

Configuration = (options={}) ->

  boot2dockerbox      = if os.type() is "Darwin" then "192.168.59.103" else "localhost"

  publicPort          = options.publicPort     or "8090"
  hostname            = options.hostname       or "lvh.me"
  protocol            = options.protocol       or "http:"
  publicHostname      = options.publicHostname or "http://#{options.hostname}"
  region              = options.region         or "dev"
  configName          = options.configName     or "dev"
  environment         = options.environment    or "dev"
  projectRoot         = options.projectRoot    or path.join __dirname, '/..'
  version             = options.version        or "2.0" # TBD
  branch              = options.branch         or "cake-rewrite"
  build               = options.build          or "1111"
  githubuser          = options.githubuser     or "koding"

  mongo               = "#{boot2dockerbox}:27017/koding"
  etcd                = "#{boot2dockerbox}:4001"

  redis               = { host:     "#{boot2dockerbox}"                           , port:               "6379"                                  , db:                 0                         }
  redis.url           = "#{redis.host}:#{redis.port}"

  rabbitmq            = { host:     "#{boot2dockerbox}"                           , port:               5672                                    , apiPort:            15672                       , login:           "guest"                              , password: "guest"                     , vhost:         "/"                                    }
  mq                  = { host:     "#{rabbitmq.host}"                            , port:               rabbitmq.port                           , apiAddress:         "#{rabbitmq.host}"          , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"         , componentUser: "#{rabbitmq.login}"                      , password:       "#{rabbitmq.password}"                   , heartbeat:       0           , vhost:        "#{rabbitmq.vhost}" }

  if options.ngrok
    scheme = 'https'
    host   = "koding-#{process.env.USER}.ngrok.com"
  else
    scheme = 'http'
    _port  = if publicPort is '80' then '' else publicPort
    host   = options.host or "#{options.hostname}:#{_port}"

  local = "127.0.0.1"
  if publicPort isnt '80'
    local = "#{local}:#{publicPort}"

  customDomain        = { public: "#{scheme}://#{host}", public_: host, local: "http://#{local}", local_: "#{local}", host: "http://lvh.me", port: 8090 }

  sendgrid            = { username: "koding"                                      , password:           "DEQl7_Dr"                            }
  email               = { host:     "#{customDomain.public_}"                     , defaultFromMail:    'hello@koding.com'                      , defaultFromName:    'Koding'                    , username:        "#{sendgrid.username}"               , password: "#{sendgrid.password}"      , forcedRecipient: "foome@koding.com"                       }
  kontrol             = { url:      "#{customDomain.public}/kontrol/kite"         , port:               3000                                    , useTLS:             no                          , certFile:        ""                                   , keyFile:  ""                          , publicKeyFile: "./certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "./certs/test_kontrol_rsa_private.pem"}
  broker              = { name:     "broker"                                      , serviceGenericName: "broker"                                , ip:                 ""                          , webProtocol:     "http:"                              , host:     "#{customDomain.public}"    , port:          8008                                     , certFile:       ""                                       , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: "#{customDomain.public}" }
  regions             = { kodingme: "#{configName}"                               , vagrant:            "vagrant"                               , sj:                 "sj"                        , aws:             "aws"                                , premium:  "vagrant"                 }
  algolia             = { appId:    'DYVV81J2S1'                                  , apiKey:             '303eb858050b1067bcd704d6cbfb977c'      , indexSuffix:        ".#{ os.hostname() }"     }
  algoliaSecret       = { appId:    "#{algolia.appId}"                            , apiKey:             "#{algolia.apiKey}"                     , indexSuffix:        algolia.indexSuffix         , apiSecretKey:    '041427512bcdcd0c7bd4899ec8175f46' }
  mixpanel            = { token:    "a57181e216d9f713e19d5ce6d6fb6cb3"            , enabled:            no                                    }
  postgres            = { host:     "#{boot2dockerbox}"                           , port:               5432                                    , username:           "socialapplication"         , password:        "socialapplication"                  , dbname:   "social"                  }
  kontrolPostgres     = { host:     "#{boot2dockerbox}"                           , port:               5432                                    , username:           "kontrolapplication"        , password:        "kontrolapplication"                 , dbname:   "social"                  }
  kiteHome            = "#{projectRoot}/kite_home/koding"
  pubnub              = { publishkey: "pub-c-ed2a8027-1f8a-4070-b0ec-d4ad535435f6", subscribekey: "sub-c-00d2be66-8867-11e4-9b60-02ee2ddab7fe"  , secretkey: "sec-c-Mzg5ZTMzOTAtYjQxOC00YTc5LWJkNWEtZmI3NTk3ODA5YzAx"                                     , serverAuthKey: "689b3039-439e-4ca6-80c2-3b0b17e3f2f3b3736a37-554c-44a1-86d4-45099a98c11a"       , origin: "pubsub.pubnub.com"                              , enabled:  yes                         }
  gatekeeper          = { host:     "localhost"                                   , port:               7200                                    , pubnub: pubnub                                }
  paymentwebhook      = { port : "6600", debug : true }

  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go

  kloudPort           = 5500
  kloud               = { port : kloudPort, privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile, kontrolUrl: kontrol.url, registerUrl : "#{customDomain.public}/kloud/kite", secretKey :  "J7suqUXhqXeiLchTrBDvovoJZEBVPxncdHyHCYqnGfY4HirKCe", address : "http://localhost:#{kloudPort}/kite"}

  googleapiServiceAccount = {clientId       :  "753589381435-irpve47dabrj9sjiqqdo2k9tr8l1jn5v.apps.googleusercontent.com", clientSecret : "1iNPDf8-F9bTKmX8OWXlkYra" , serviceAccountEmail    : "753589381435-irpve47dabrj9sjiqqdo2k9tr8l1jn5v@developer.gserviceaccount.com", serviceAccountKeyFile : "#{projectRoot}/keys/googleapi-privatekey.pem"}

  segment                 = 'kb2hfdgf20'

  socialapi =
    proxyUrl                : "#{customDomain.local}/api/social"
    port                    : "7000"
    configFilePath          : "#{projectRoot}/go/src/socialapi/config/dev.toml"
    postgres                : postgres
    mq                      : mq
    redis                   :  url: redis.url
    mongo                   : mongo
    environment             : environment
    region                  : region
    hostname                : host
    protocol                : protocol
    email                   : email
    sitemap                 : { redisDB: 0, updateInterval:  "1m" }
    algolia                 : algoliaSecret
    mixpanel                : mixpanel
    limits                  : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: 30 }
    eventExchangeName       : "BrokerMessageBus"
    disableCaching          : no
    debug                   : no
    stripe                  : { secretToken : "sk_test_2ix1eKPy8WtfWTLecG9mPOvN" }
    paypal                  : { username: 'senthil+1_api1.koding.com', password: 'JFH6LXW97QN588RC', signature: 'AFcWxV21C7fd0v3bYYYRCpSSRl31AjnvzeXiWRC89GOtfhnGMSsO563z', returnUrl: "#{customDomain.public}/-/payments/paypal/return", cancelUrl: "#{customDomain.public}/-/payments/paypal/cancel", isSandbox: yes }
    gatekeeper              : gatekeeper
    customDomain            : customDomain
    kloud                   : { secretKey: kloud.secretKey, address: kloud.address }
    paymentwebhook          : paymentwebhook
    googleapiServiceAccount : googleapiServiceAccount
    segment                 : segment

  userSitesDomain     = "dev.koding.io"
  socialQueueName     = "koding-social-#{configName}"
  logQueueName        = socialQueueName+'log'
  autoConfirmAccounts = yes

  KONFIG              =
    configName                     : configName
    environment                    : environment
    regions                        : regions
    region                         : region
    hostname                       : host
    protocol                       : protocol
    publicPort                     : publicPort
    publicHostname                 : publicHostname
    version                        : version
    broker                         : broker
    uri                            : address: customDomain.public
    userSitesDomain                : userSitesDomain
    autoConfirmAccounts            : autoConfirmAccounts
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    kiteHome                       : kiteHome
    redis                          : redis.url
    monitoringRedis                : redis.url
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #

    vmwatcher                      : {port          : "6400"              , awsKey    : "AKIAI6KPPX7WUT3XAYIQ"     , awsSecret         : "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"                                                                 , kloudSecretKey : kloud.secretKey                                           , kloudAddr : kloud.address, connectToKlient: true, debug: false, mongo: mongo, redis: redis.url }
    gowebserver                    : {port          : 6500}
    webserver                      : {port          : 8080                , useCacheHeader: no                     , kitePort          : 8860}
    authWorker                     : {login         : "#{rabbitmq.login}" , queueName : socialQueueName+'auth'     , authExchange      : "auth"                                  , authAllExchange : "authAll"                                      , port  : 9530 }
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'    , cronDaily : '0 10 0 * * *'             , run               : no                                      , forcedRecipient: email.forcedRecipient                           , maxAge: 3      , port  : 9540 }
    elasticSearch                  : {host          : "#{boot2dockerbox}" , port      : 9200                       , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                , login     : "#{rabbitmq.login}"        , queueName         : socialQueueName                         , kitePort        : 8760 }
    email                          : email
    newkites                       : {useTLS        : no                  , certFile  : ""                         , keyFile: "#{projectRoot}/kite_home/koding/kite.key"}
    log                            : {login         : "#{rabbitmq.login}" , queueName : logQueueName}
    boxproxy                       : {port          : 8090 }
    sourcemaps                     : {port          : 3526 }
    appsproxy                      : {port          : 3500 }
    rerouting                      : {port          : 9500 }
    kloud                          : kloud
    emailConfirmationCheckerWorker : {enabled: no                         , login : "#{rabbitmq.login}"            , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                                      , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol
    gatekeeper                     : gatekeeper

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
    datadog                        : {api_key       : "6d3e00fb829d97cb6ee015f80063627c"             , app_key       : "c9be251621bc75acf4cd040e3edea17fff17a13a"}
    statsd                         : {use           : false                                          , ip            : "#{customDomain.public}"                       , port: 8125}
    graphite                       : {use           : false                                          , host          : "#{customDomain.public}"                       , port: 2003}
    sessionCookie                  : {maxAge        : 1000 * 60 * 60 * 24 * 14                       , secure        : no}
    logLevel                       : {neo4jfeeder   : "notice"                                       , oskite: "info"                                               , terminal: "info"                                                                      , kontrolproxy  : "notice"                                           , kontroldaemon : "notice"                                           , userpresence  : "notice"                                          , vmproxy: "notice"      , graphitefeeder: "notice"                                                           , sync: "notice" , topicModifier : "notice" , postModifier  : "notice" , router: "notice" , rerouting: "notice" , overview: "notice" , amqputil: "notice" , rabbitMQ: "notice" , ldapserver: "notice" , broker: "notice"}
    aws                            : {key           : "AKIAJSUVKX6PD254UGAA"                         , secret        : "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"}
    embedly                        : {apiKey        : "94991069fb354d4e8fdb825e52d4134a" }
    troubleshoot                   : {recipientEmail: "can@koding.com" }
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    recaptcha                      : '6LdLAPcSAAAAAJe857OKXNdYzN3C1D55DwGW0RgT'
    mixpanel                       : mixpanel.token
    segment                        : segment
    googleapiServiceAccount        : googleapiServiceAccount
    siftScience                    : 'a41deacd57929378'
    prerenderToken                 : 'St4CU4a5hvfYCEOboftc'
    tokbox                         : { API_KEY: '45082272', API_SECRET: 'fb232a623fa9936ace8d8f9826c3e4a942d457b8' }

    collaboration :
      timeout     : 1 * 60 * 1000

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client                         : {watch: yes , version       : version , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  # NOTE: when you add to runtime options below, be sure to modify
  # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`

  KONFIG.client.runtimeOptions =
    kites                : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia              : algolia
    logToExternal        : no                                 # rollbar                                            , mixpanel etc.
    suppressLogs         : no
    logToInternal        : no                                 # log worker
    authExchange         : "auth"
    environment          : environment                        # this is where browser knows what kite environment to query for
    version              : version
    resourceName         : socialQueueName
    userSitesDomain      : userSitesDomain
    logResourceName      : logQueueName
    socialApiUri         : "/xhr"
    apiUri               : null
    sourceMapsUri        : "/sourcemaps"
    mainUri              : null
    broker               : uri  : "/subscribe"
    appsUri              : "/appsproxy"
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout     : 1000 * 15
    userIdleMs           : 1000 * 60 * 5
    embedly              : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    github               : {clientId     : "f8e440b796d953ea01e5" }
    newkontrol           : {url          : "#{kontrol.url}"}
    sessionCookie        : {maxAge       : 1000 * 60 * 60 * 24 * 14 , secure: no   }
    troubleshoot         : {idleTime     : 1000 * 60 * 60           , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    recaptcha            : '6LdLAPcSAAAAAG27qiKqlnowAM8FXfKSpW1wx_bU'
    stripe               : { token: 'pk_test_S0cUtuX2QkSa5iq0yBrPNnJF' }
    externalProfiles     :
      google             : {nicename: 'Google'  }
      linkedin           : {nicename: 'LinkedIn'}
      twitter            : {nicename: 'Twitter' }
      odesk              : {nicename: 'oDesk'   , urlLocation: 'info.profile_url' }
      facebook           : {nicename: 'Facebook', urlLocation: 'link'             }
      github             : {nicename: 'GitHub'  , urlLocation: 'html_url'         }
    entryPoint           : {slug:'koding'       , type:'group'}
    siftScience          : 'f270274999'
    paypal               : { formUrl: 'https://www.sandbox.paypal.com/incontext' }
    pubnub               : { subscribekey: pubnub.subscribekey , ssl: no,  enabled: yes     }
    collaboration        : KONFIG.collaboration
    paymentBlockDuration : 2 * 60 * 1000 # 2 minutes

    # NOTE: when you add to runtime options above, be sure to modify
    # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`

    # END: PROPERTIES SHARED WITH BROWSER #


  #--- RUNTIME CONFIGURATION: WORKERS AND KITES ---#
  GOBIN = "#{projectRoot}/go/bin"
  GOPATH= "#{projectRoot}/go"


  # THESE COMMANDS WILL EXECUTE IN PARALLEL.

  KONFIG.workers =
    gowebserver         :
      group             : "webserver"
      ports             :
         incoming       : "#{KONFIG.gowebserver.port}"
      supervisord       :
        command         : "#{GOBIN}/watcher -run koding/go-webserver -c #{configName}"
      nginx             :
        locations       : [ location: "~^/IDE/.*" ]
      healthCheckURL    : "http://localhost:#{KONFIG.gowebserver.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.gowebserver.port}/version"

    kontrol             :
      group             : "environment"
      ports             :
        incoming        : "#{kontrol.port}"
      supervisord       :
        command         : "#{GOBIN}/kontrol -region #{region} -machines #{etcd} -environment #{environment} -mongourl #{KONFIG.mongo} -port #{kontrol.port} -privatekey #{kontrol.privateKeyFile} -publickey #{kontrol.publicKeyFile} -storage postgres -postgres-dbname #{kontrolPostgres.dbname} -postgres-host #{kontrolPostgres.host} -postgres-port #{kontrolPostgres.port} -postgres-username #{kontrolPostgres.username} -postgres-password #{kontrolPostgres.password}"
      nginx             :
        disableLocation : yes
      healthCheckURL    : "http://localhost:#{KONFIG.kontrol.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kontrol.port}/version"

    kloud               :
      group             : "environment"
      ports             :
        incoming        : "#{KONFIG.kloud.port}"
      supervisord       :
        command         : "#{GOBIN}/kloud -networkusageendpoint http://localhost:#{KONFIG.vmwatcher.port} -planendpoint #{socialapi.proxyUrl}/payments/subscriptions  -hostedzone #{userSitesDomain} -region #{region} -environment #{environment} -port #{KONFIG.kloud.port} -publickey #{kontrol.publicKeyFile} -privatekey #{kontrol.privateKeyFile} -kontrolurl #{kontrol.url}  -registerurl #{KONFIG.kloud.registerUrl} -mongourl #{KONFIG.mongo} -prodmode=#{configName is "prod"}"
      nginx             :
        websocket       : yes
        locations       : [ location: "~^/kloud/.*" ]
      healthCheckURL    : "http://localhost:#{KONFIG.kloud.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kloud.port}/version"

    ngrokProxy          :
      group             : "environment"
      supervisord       :
        command         : "coffee #{projectRoot}/ngrokProxy --user #{process.env.USER}"

    broker              :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.broker.port}"
      supervisord       :
        command         : "#{GOBIN}/watcher -run koding/broker -c #{configName}"
      nginx             :
        websocket       : yes
        locations       : [
          { location    : "/websocket" }
          { location    : "~^/subscribe/.*" }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.broker.port}/info"
      versionURL        : "http://localhost:#{KONFIG.broker.port}/version"

    rerouting           :
      group             : "webserver"
      supervisord       :
        command         : "#{GOBIN}/watcher -run koding/rerouting -c #{configName}"
      healthCheckURL    : "http://localhost:#{KONFIG.rerouting.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.rerouting.port}/version"

    authworker          :
      group             : "webserver"
      supervisord       :
        command         : "./watch-node #{projectRoot}/workers/auth/index.js -c #{configName} -p #{KONFIG.authWorker.port} --disable-newrelic"
      healthCheckURL    : "http://localhost:#{KONFIG.authWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.authWorker.port}/version"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      supervisord       :
        command         : "./watch-node #{projectRoot}/servers/sourcemaps/index.js -c #{configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"

    emailsender         :
      group             : "webserver"
      supervisord       :
        command         : "./watch-node #{projectRoot}/workers/emailsender/index.js  -c #{configName} -p #{KONFIG.emailWorker.port} --disable-newrelic"
      healthCheckURL    : "http://localhost:#{KONFIG.emailWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.emailWorker.port}/version"

    appsproxy           :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.appsproxy.port}"
      supervisord       :
        command         : "./watch-node #{projectRoot}/servers/appsproxy/web.js -c #{configName} -p #{KONFIG.appsproxy.port} --disable-newrelic"

    webserver           :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.webserver.port}"
        outgoing        : "#{KONFIG.webserver.kitePort}"
      supervisord       :
        command         : "./watch-node #{projectRoot}/servers/index.js -c #{configName} -p #{KONFIG.webserver.port}                 --disable-newrelic --kite-port=#{KONFIG.webserver.kitePort} --kite-key=#{kiteHome}/kite.key"
      nginx             :
        locations       : [ location: "/" ]

    socialworker        :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.social.port}"
        outgoing        : "#{KONFIG.social.kitePort}"
      supervisord       :
        command         : "./watch-node #{projectRoot}/workers/social/index.js -c #{configName} -p #{KONFIG.social.port} -r #{region} --disable-newrelic --kite-port=#{KONFIG.social.kitePort} --kite-key=#{kiteHome}/kite.key"
      nginx             :
        locations       : [ location: "/xhr" ]
      healthCheckURL    : "http://localhost:#{KONFIG.social.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.social.port}/version"

    socialapi:
      group             : "socialapi"
      instances         : 1
      ports             :
        incoming        : "#{socialapi.port}"
      supervisord       :
        command         : "cd #{projectRoot}/go/src/socialapi && make develop -j config=#{socialapi.configFilePath} && cd #{projectRoot}"
      healthCheckURL    : "#{socialapi.proxyUrl}/healthCheck"
      versionURL        : "#{socialapi.proxyUrl}/version"
      nginx             :
        locations       : [
          # location ordering is important here. if you are going to need to change it or
          # add something new, thoroughly test it in sandbox. Most of the problems are not occuring
          # in dev environment
          {
            location    : "~ /api/social/channel/(.*)/history/count"
            proxyPass   : "http://socialapi/channel/$1/history/count$is_args$args"
          }
          {
            location    : "~ /api/social/channel/(.*)/history"
            proxyPass   : "http://socialapi/channel/$1/history$is_args$args"
          }
          {
            location    : "~ /api/social/collaboration/ping"
            proxyPass   : "http://socialapi/collaboration/ping$1$is_args$args"
          }
          {
            location    : "~ /api/social/(.*)"
            proxyPass   : "http://socialapi/$1$is_args$args"
            internalOnly: yes
          }
          {
            location    : "~ /sitemap(.*).xml"
            proxyPass   : "http://socialapi/sitemap$1.xml"
          }
        ]

    gatekeeper          :
      group             : "socialapi"
      ports             :
        incoming        : "#{gatekeeper.port}"
      supervisord       :
        command         : "cd #{projectRoot}/go/src/socialapi && make gatekeeperdev config=#{socialapi.configFilePath} && cd #{projectRoot}"
      healthCheckURL    : "#{customDomain.local}/api/gatekeeper/healthCheck"
      versionURL        : "#{customDomain.local}/api/gatekeeper/version"
      nginx             :
        locations       : [
          location      : "~ /api/gatekeeper/(.*)"
          proxyPass     : "http://gatekeeper/$1$is_args$args"
        ]

    dispatcher          :
      group             : "socialapi"
      supervisord       :
        command         : "cd #{projectRoot}/go/src/socialapi && make dispatcherdev config=#{socialapi.configFilePath} && cd #{projectRoot}"

    paymentwebhook      :
      group             : "socialapi"
      ports             :
        incoming        : paymentwebhook.port
      supervisord       :
        command         : "cd #{projectRoot}/go/src/socialapi && make paymentwebhookdev config=#{socialapi.configFilePath} && cd #{projectRoot}"
      healthCheckURL    : "http://localhost:#{paymentwebhook.port}/healthCheck"
      versionURL        : "http://localhost:#{paymentwebhook.port}/version"
      nginx             :
        locations       : [
          { location    : "= /-/payments/stripe/webhook" },
        ]

    vmwatcher           :
      group             : "environment"
      instances         : 1
      ports             :
        incoming        : "#{KONFIG.vmwatcher.port}"
      supervisord       :
        command         : "#{GOBIN}/watcher -run koding/vmwatcher"
      healthCheckURL    : "http://localhost:#{KONFIG.vmwatcher.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.vmwatcher.port}/version"

  #-------------------------------------------------------------------------#
  #---- SECTION: AUTO GENERATED CONFIGURATION FILES ------------------------#
  #---- DO NOT CHANGE ANYTHING BELOW. IT'S GENERATED FROM WHAT'S ABOVE  ----#
  #-------------------------------------------------------------------------#

  KONFIG.JSON = JSON.stringify KONFIG

  #---- SUPERVISOR CONFIG ----#

  generateRunFile = (KONFIG) ->

    killlist = ->
      str = "kill -KILL "
      str += "$#{key}pid " for key,val of KONFIG.workers

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
          #{val.supervisord.command} &>#{projectRoot}/.logs/#{key}.log &
          #{key}pid=$!
          echo [#{key}] started with pid: $#{key}pid


        }

        function worker_#{key} {

          #------------- worker: #{key} -------------#
          #{val.supervisord.command}

        }

        """
      return workers

    installScript = """
        cd #{projectRoot}
        git submodule update --init

        npm install --unsafe-perm

        echo '#---> BUILDING CLIENT <---#'
        sh -c "scripts/install-npm.sh -d client -u -p -s"
        make -C #{projectRoot}/client dist

        echo '#---> BUILDING GO WORKERS (@farslan) <---#'
        #{projectRoot}/go/build.sh

        echo '#---> BUILDING SOCIALAPI (@cihangir) <---#'
        cd #{projectRoot}/go/src/socialapi
        make configure
        # make install
        cd #{projectRoot}
        cleanchatnotifications

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

      SERVICES="mongo redis postgres rabbitmq"

      NGINX_CONF="#{projectRoot}/.dev.nginx.conf"
      NGINX_PID="#{projectRoot}/.dev.nginx.pid"

      #{envvars()}

      trap ctrl_c INT

      function ctrl_c () {
        echo "ctrl_c detected. killing all processes..."
        kill_all
      }

      function kill_all () {
        #{killlist()}

        echo "killing hung processes"
        # there is race condition, that killlist() can not kill all process
        sleep 3


        # both of them are  required
        ps aux | grep koding | grep -E 'node|go/bin' | awk '{ print $2 }' | xargs kill -9
        pkill -9 koding-
      }

      function nginxstop () {
        if [ -a $NGINX_PID ]; then
          echo "stopping nginx"
          nginx -c $NGINX_CONF -g "pid $NGINX_PID;" -s quit
        fi
      }

      function nginxrun () {
        nginxstop
        echo "starting nginx"
        nginx -c $NGINX_CONF -g "pid $NGINX_PID;"
      }

      function checkrunfile () {

        checkpackagejsonfile

        if [ "#{projectRoot}/run" -ot "#{projectRoot}/config/main.dev.coffee" ]; then
            echo your run file is older than your config file. doing ./configure.
            sleep 1
            ./configure

            echo -e "\n\nPlease do ./run again\n"
            exit 1;
        fi

        if [ "#{projectRoot}/run" -ot "#{projectRoot}/configure" ]; then
            echo your run file is older than your configure file. doing ./configure.
            sleep 1
            ./configure

            echo -e "\n\nPlease do ./run again\n"
            exit 1;
        fi
      }

      function checkpackagejsonfile () {
        if [ "#{projectRoot}/run" -ot "#{projectRoot}/package.json" ]; then
            echo your run file is older than your package json. doing npm i.
            sleep 1
            npm i

            echo -e "\n\nPlease do ./configure and  ./run again\n"
            exit 1;
        fi

        if [ "#{projectRoot}/run" -ot "#{projectRoot}/client/package.json" ]; then
            sleep 1
            sh -c "scripts/install-npm.sh -d client -s"
        fi

        if [ "#{projectRoot}/run" -ot "#{projectRoot}/client/builder/package.json" ]; then
            sleep 1
            sh -c "scripts/install-npm.sh -d client/builder -s"
        fi

        if [ "#{projectRoot}/run" -ot "#{projectRoot}/client/landing/package.json" ]; then
            sleep 1
            sh -c "scripts/install-npm.sh -d client/landing -s"
        fi

        OLD_COOKIE=$(npm list tough-cookie -s | grep 0.9.15 | wc -l | awk \'{printf "%s", $1}\')
        if [  $OLD_COOKIE -ne 0 ]; then
            echo "You have tough-cookie@0.9.15 installed on your system, please remove node_modules directory and do npm i again";
            exit 1;
        fi
      }


      function testendpoints () {

        EP=("lvh.me:8090/" "lvh.me:8090/xhr" "lvh.me:8090/subscribe/info" "lvh.me:8090/kloud/kite" "lvh.me:8090/kontrol/kite" "lvh.me:8090/appsproxy" "lvh.me:8090/sourcemaps")

        while [ 1==1 ];
        do
        for i in "${EP[@]}"
          do

             curl $i -s -f -o /dev/null || echo "DOWN $i" # | mail -s "Website is down" admin@thesite.com

          done
        sleep 1
        done
      }



      function chaosmonkey () {

        while [ 1==1 ]; do
          for i in mongo redis postgres
            do
              echo stopping $i
              docker stop $i
              echo starting $i
              docker start $i
              sleep 10
            done
        done

        echo now do "run services" again to make sure everything is back to normal..
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

        # Check if PG DB schema update required
        go run go/src/socialapi/tests/pg-update.go #{postgres.host} #{postgres.port}
        RESULT=$?

        if [ $RESULT -ne 0 ]; then
          exit 1
        fi

        # Check everything else
        check

        # Do npm i incase of packages.json changes
        npm i --silent

        # this is a temporary adition, normally file watcher should delete the created file later on
        cd #{projectRoot}/go/bin

        # Remove old watcher files (do we still need this?)
        rm -rf goldorf-main-*
        rm -rf watcher-*

        # Run Go builder
        #{projectRoot}/go/build.sh

        # Run Social Api builder
        cd #{projectRoot}/go/src/socialapi
        make configure

        cd #{projectRoot}

        # Do PG Migration if necessary
        migrate up

        # a temporary migration line (do we still need this?)
        env PGPASSWORD=#{postgres.password} psql -tA -h #{postgres.host} #{postgres.dbname} -U #{postgres.username} -c "ALTER TYPE \"api\".\"channel_type_constant_enum\" ADD VALUE IF NOT EXISTS 'collaboration';"

        # Create default workspaces
        node scripts/create-default-workspace

        # Run all the worker daemons in KONFIG.workers
        #{("worker_daemon_"+key+"\n" for key,val of KONFIG.workers).join(" ")}

        # Check backend option, if it's then bypass client build
        if [ "$1" == "backend" ] ; then

          echo
          echo '---------------------------------------------------------------'
          echo '>>> CLIENT BUILD DISABLED! DO "make -C client" MANUALLY <<<'
          echo '---------------------------------------------------------------'
          echo

        else
          sh -c "scripts/install-npm.sh -d client -u -p -s"
          make -C #{projectRoot}/client
        fi

        # Show the all logs of workers
        tail -fq ./.logs/*.log

      }

      #{workersRunList()}


      function printHelp (){

        echo "Usage: "
        echo ""
        echo "  run                       : to start koding"
        echo "  run backend               : to start only backend of koding"
        echo "  run killall               : to kill every process started by run script"
        echo "  run install               : to compile/install client and "
        echo "  run buildclient           : to see of specified worker logs only"
        echo "  run logs                  : to see all workers logs"
        echo "  run log [worker]          : to see of specified worker logs only"
        echo "  run buildservices         : to initialize and start services"
        echo "  run buildservices sandbox : to initialize and start services on sandbox"
        echo "  run resetdb               : to reset databases"
        echo "  run services              : to stop and restart services"
        echo "  run worker                : to list workers"
        echo "  run chaosmonkey           : to restart every service randomly to test resilience."
        echo "  run testendpoints         : to test every URL endpoint programmatically."
        echo "  run printconfig           : to print koding config environment variables (output in json via --json flag)"
        echo "  run worker [worker]       : to run a single worker"
        echo "  run supervisor [env]      : to show status of workers in that environment"
        echo "  run migrate [command]     : to apply/revert database changes (command: [create|up|down|version|reset|redo|to|goto])"
        echo "  run help                  : to show this list"
        echo ""

      }

      function migrate () {
        params=(create up down version reset redo to goto)
        param=$1

        case "${params[@]}" in  *"$param"*)
          ;;
        *)
          echo "Error: Command not found: $param"
          echo "Usage: run migrate COMMAND [arg]"
          echo ""
          echo "Commands:  "
          echo "  create [filename] : create new migration file in path"
          echo "  up                : apply all available migrations"
          echo "  down              : roll back all migrations"
          echo "  redo              : roll back the most recently applied migration, then run it again"
          echo "  reset             : run down and then up command"
          echo "  version           : show the current migration version"
          echo "  to   [n]          : (+n) apply the next n / (-n) roll back the previous n migrations"
          echo "  goto [n]          : go to specific migration"

          echo ""
          exit 1
        ;;
        esac

        if [ "$param" == "to" ]; then
          param="migrate"
        elif [ "$param" == "create" ] && [ -z "$2" ]; then
          echo "Please choose a migration file name. (ex. add_created_at_column_account)"
          echo "Usage: run migrate create [filename]"
          echo ""
          exit 1
        fi

        #{GOBIN}/migrate -url "postgres://#{postgres.host}:#{postgres.port}/#{postgres.dbname}?user=social_superuser&password=social_superuser" -path "#{projectRoot}/go/src/socialapi/db/sql/migrations" $param $2

        if [ "$param" == "create" ]; then
          echo "Please edit created script files and add them to your repository."
        fi

      }

      function check (){

        check_service_dependencies

        if [[ `uname` == 'Darwin' ]]; then
          if [ -z "$DOCKER_HOST" ]; then
            echo "You need to export DOCKER_HOST, run 'boot2docker up' and follow the instructions."
            exit 1
          fi
        fi

        mongo #{mongo} --eval "db.stats()" > /dev/null  # do a simple harmless command of some sort

        RESULT=$?   # returns 0 if mongo eval succeeds

        if [ $RESULT -ne 0 ]; then
            echo ""
            echo "Can't talk to mongodb at #{mongo}, is it not running? exiting."
            exit 1
        fi

        EXISTS=$(PGPASSWORD=kontrolapplication psql -tA -h #{boot2dockerbox} social -U kontrolapplication -c "Select 1 from pg_tables where tablename = 'kite' AND schemaname = 'kite';")
        if [[ $EXISTS != '1' ]]; then
          echo ""
          echo "You don't have the new Kontrol Postgres. Please call ./run buildservices."
          exit 1
        fi

      }

      function check_psql () {
        command -v psql          >/dev/null 2>&1 || { echo >&2 "I require psql but it's not installed. (brew install postgresql)  Aborting."; exit 1; }
      }

      function check_service_dependencies () {
        echo "checking required services: nginx, docker, mongo, graphicsmagick..."
        command -v go            >/dev/null 2>&1 || { echo >&2 "I require go but it's not installed.  Aborting."; exit 1; }
        command -v docker        >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
        command -v nginx         >/dev/null 2>&1 || { echo >&2 "I require nginx but it's not installed. (brew install nginx maybe?)  Aborting."; exit 1; }
        command -v mongorestore  >/dev/null 2>&1 || { echo >&2 "I require mongorestore but it's not installed.  Aborting."; exit 1; }
        command -v node          >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed.  Aborting."; exit 1; }
        command -v npm           >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }
        command -v gulp          >/dev/null 2>&1 || { echo >&2 "I require gulp but it's not installed. (npm i gulp -g)  Aborting."; exit 1; }
        # command -v stylus      >/dev/null 2>&1 || { echo >&2 "I require stylus  but it's not installed. (npm i stylus -g)  Aborting."; exit 1; }
        command -v coffee        >/dev/null 2>&1 || { echo >&2 "I require coffee-script but it's not installed. (npm i coffee-script -g)  Aborting."; exit 1; }
        check_psql

        if [[ `uname` == 'Darwin' ]]; then
          brew info graphicsmagick >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
          command -v boot2docker   >/dev/null 2>&1 || { echo >&2 "I require boot2docker but it's not installed.  Aborting."; exit 1; }
        elif [[ `uname` == 'Linux' ]]; then
          command -v gm >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }


        fi
        check_gulp_version
      }

      function check_gulp_version () {
           VERSION=$(npm info gulp version 2> /dev/null)

           while IFS=".", read MAJOR MINOR REVISION; do
              if [[ $MAJOR -lt 3 ]]; then
                  MISMATCH=1
              elif [[ $MAJOR -eq 3 && $MINOR -lt 7 ]]; then
                  MISMATCH=1
              fi
          done < <(echo $VERSION)

          if [[ -n $MISMATCH ]]; then
              echo 'Installed gulp version must be >= 3.7.0'
              exit 1
          fi
      }

      function build_services () {

        if [[ `uname` == 'Darwin' ]]; then
          boot2docker up
        fi

        echo "Stopping services: $SERVICES"
        docker stop $SERVICES

        echo "Removing services: $SERVICES"
        docker rm   $SERVICES

        # Build Mongo service
        cd #{projectRoot}/install/docker-mongo
        docker build -t koding/mongo .

        # Build rabbitMQ service
        cd #{projectRoot}/install/docker-rabbitmq
        docker build -t koding/rabbitmq .

        # Build postgres
        cd #{projectRoot}/go/src/socialapi/db/sql

        # Include this to dockerfile before we continute with building
        mkdir -p kontrol
        cp #{projectRoot}/go/src/github.com/koding/kite/kontrol/*.sql kontrol/
        sed -i -e 's/somerandompassword/kontrolapplication/' kontrol/001-schema.sql

        docker build -t koding/postgres .

        docker run -d -p 27017:27017              --name=mongo    koding/mongo --dbpath /data/db --smallfiles --nojournal
        docker run -d -p 5672:5672 -p 15672:15672 --name=rabbitmq koding/rabbitmq

        docker run -d -p 6379:6379                --name=redis    redis
        docker run -d -p 5432:5432                --name=postgres koding/postgres

        restoredefaultmongodump

        echo "#---> CLEARING ALGOLIA INDEXES: @chris <---#"
        cd #{projectRoot}
        ./scripts/clear-algolia-index.sh -i "accounts$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
        ./scripts/clear-algolia-index.sh -i "topics$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
        ./scripts/clear-algolia-index.sh -i "messages$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"

        migrate up
      }

      function services () {

        if [[ `uname` == 'Darwin' ]]; then
          boot2docker up
        fi
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

        nginxrun
      }


      function importusers () {

        cd #{projectRoot}
        node #{projectRoot}/scripts/user-importer

        migrateusers

      }

      function migrateusers () {

        echo '#---> UPDATING MONGO DB TO WORK WITH SOCIALAPI @cihangir <---#'
        mongo #{mongo} --eval='db.jAccounts.update({},{$unset:{socialApiId:0}},{multi:true}); db.jGroups.update({},{$unset:{socialApiChannelId:0}},{multi:true});'

        go run ./go/src/socialapi/workers/cmd/migrator/main.go -c #{socialapi.configFilePath}

        # Required step for guestuser
        mongo #{mongo} --eval='db.jAccounts.update({"profile.nickname":"guestuser"},{$set:{type:"unregistered", socialApiId:0}});'

      }

      function restoredefaultmongodump () {

        echo '#---> CREATING VANILLA KODING DB @gokmen <---#'

        mongo #{mongo} --eval "db.dropDatabase()"

        cd #{projectRoot}/install/docker-mongo
        tar jxvf #{projectRoot}/install/docker-mongo/default-db-dump.tar.bz2
        mongorestore -h#{boot2dockerbox} -dkoding dump/koding
        rm -rf ./dump

        echo '#---> UPDATING MONGO DATABASE ACCORDING TO LATEST CHANGES IN CODE (UPDATE PERMISSIONS @chris) <---#'
        cd #{projectRoot}
        node #{projectRoot}/scripts/permission-updater  -c #{socialapi.configFilePath} --hard >/dev/null

      }

      function updateusers () {

        cd #{projectRoot}
        node #{projectRoot}/scripts/user-updater

      }

      function create_default_workspace () {

        node #{projectRoot}/scripts/create-default-workspace

      }

      function cleanchatnotifications () {
        cd #{GOBIN}
        ./notification -c #{socialapi.configFilePath} -h
      }

      function sandbox_buildservices () {
        SANDBOX_SERVICES=54.165.122.100
        SANDBOX_WEB_1=54.165.177.88
        SANDBOX_WEB_2=54.84.179.170

        echo "cd /opt/koding; ./run buildservices" | ssh root@$SANDBOX_SERVICES @/bin/bash

        echo "sudo supervisorctl restart all"      | ssh ec2-user@$SANDBOX_WEB_1 /bin/bash
        echo "sudo supervisorctl restart all"      | ssh ec2-user@$SANDBOX_WEB_2 /bin/bash
      }

      if [[ "$1" == "killall" ]]; then

        kill_all

      elif [ "$1" == "install" ]; then
        check_service_dependencies
        #{installScript}

      elif [ "$1" == "printconfig" ]; then

        printconfig $@

      elif [[ "$1" == "log" || "$1" == "logs" ]]; then

        trap - INT
        trap

        if [ "$2" == "" ]; then
          tail -fq ./.logs/*.log
        else
          tail -fq ./.logs/$2.log
        fi

      elif [ "$1" == "cleanup" ]; then

        ./cleanup $@

      elif [ "$1" == "buildclient" ]; then

        sh -c "scripts/install-npm.sh -d client -u -p -s"
        make -C #{projectRoot}/client dist

      elif [ "$1" == "services" ]; then
        check_service_dependencies
        services

      elif [ "$1" == "resetdb" ]; then

        if [ "$2" == "--yes" ]; then

          restoredefaultmongodump
          migrateusers

          exit 0

        fi

        read -p "This will reset current databases, all data will be lost! (y/N)" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
            exit 1
        fi

        restoredefaultmongodump
        migrateusers

      elif [ "$1" == "buildservices" ]; then

        if [ "$2" == "sandbox" ]; then
          read -p "This will destroy sandbox databases (y/N)" -n 1 -r
          echo ""
          if [[ ! $REPLY =~ ^[Yy]$ ]]
          then
              exit 1
          fi

          sandbox_buildservices
          exit 0
        fi

        check_service_dependencies

        if [ "$2" != "force" ]; then
          read -p "This will destroy existing images, do you want to continue? (y/N)" -n 1 -r
          echo ""
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
          fi
        fi

        build_services
        importusers

      elif [ "$1" == "help" ]; then
        printHelp

      elif [ "$1" == "chaosmonkey" ]; then
        chaosmonkey

      elif [ "$1" == "testendpoints" ]; then
        testendpoints

      elif [ "$1" == "importusers" ]; then
        importusers

      elif [ "$1" == "updateusers" ]; then
        updateusers

      elif [ "$1" == "create_default_workspace" ]; then
        create_default_workspace

      elif [ "$1" == "cleanchatnotifications" ]; then
        cleanchatnotifications

      elif [ "$1" == "worker" ]; then

        if [ "$2" == "" ]; then
          echo Available workers:
          echo "-------------------"
          echo '#{workerList "\n"}'
        else
          trap - INT
          trap
          eval "worker_$2"
        fi

      elif [ "$1" == "supervisor" ]; then

        SUPERVISOR_ENV=$2
        if [ $SUPERVISOR_ENV == "" ]; then
          SUPERVISOR_ENV="production"
        fi

        go run scripts/supervisor_status.go $SUPERVISOR_ENV
        open supervisor.html

      elif [ "$1" == "migrate" ]; then
        check_psql

        if [ -z "$2" ]; then
          echo "Please choose a migrate command [create|up|down|version|reset|redo|to|goto]"
          echo ""
        else
          cd "#{GOPATH}/src/socialapi"
          make install-migrate
          migrate $2 $3
        fi

      elif [ "$1" == "backend" ] || [ "$#" == "0" ] ; then

        checkrunfile
        sh -c scripts/validate-npm.sh
        run $1

      else
        echo "Unknown command: $1"
        printHelp

      fi
      # ------ THIS FILE IS AUTO-GENERATED BY ./configure ----- #\n
      """
    return run

  KONFIG.ENV            = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.supervisorConf = (require "../deployment/supervisord.coffee").create KONFIG
  KONFIG.nginxConf      = (require "../deployment/nginx.coffee").create KONFIG, environment
  KONFIG.runFile        = generateRunFile        KONFIG

  return KONFIG

module.exports = Configuration


# -*- mode: coffee -*-
# vi: set ft=coffee nowrap :
