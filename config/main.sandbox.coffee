zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  prod_simulation_server = "10.0.0.248"

  publicPort     = options.publicPort          = "80"
  hostname       = options.hostname            = "sandbox.koding.com#{if publicPort is "80" then "" else ":"+publicPort}"
  protocol       = options.protocol            or "https:"
  publicHostname = options.publicHostname      = "https://#{options.hostname}"
  region         = options.region              = "aws"
  configName     = options.configName          = "sandbox"
  environment    = options.environment         = "sandbox"
  projectRoot    = options.projectRoot         or "/opt/koding"
  version        = options.tag
  tag            = options.tag
  publicIP       = options.publicIP            or "*"
  githubuser     = options.githubuser          or "koding"

  mongo               = "#{prod_simulation_server}:27017/koding"
  etcd                = "#{prod_simulation_server}:4001"

  redis               = { host:     "#{prod_simulation_server}"              , port:               6379                                  , db:              0                    }
  redis.url           = "#{redis.host}:#{redis.port}"

  rabbitmq            = { host:     "#{prod_simulation_server}"              , port:               5672                                  , apiPort:         15672                  , login:           "guest"                              , password: "guest"                , vhost:         "/"                                                 }
  mq                  = { host:     "#{rabbitmq.host}"                       , port:               rabbitmq.port                         , apiAddress:      "#{rabbitmq.host}"     , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"    , componentUser: "#{rabbitmq.login}"                                   , password:       "#{rabbitmq.password}"                                , heartbeat:       0           , vhost:        "#{rabbitmq.vhost}" }
  customDomain        = { public:   "https://#{hostname}"                    , public_:            "#{hostname}"                         , local:           "http://127.0.0.1"     , local_:          "127.0.0.1"                          , port:     80                   }
  sendgrid            = { username: "koding"                                 , password:           "DEQl7_Dr"                          }
  email               = { host:     "#{customDomain.public_}"                , defaultFromMail:    'hello@koding.com'                    , defaultFromName: 'Koding'               , username:        sendgrid.username                    , password: sendgrid.password    }
  kontrol             = { url:      "#{options.publicHostname}/kontrol/kite" , port:               3000                                  , useTLS:          no                     , certFile:        ""                                   , keyFile:  ""                     , publicKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_private.pem"}
  broker              = { name:     "broker"                                 , serviceGenericName: "broker"                              , ip:              ""                     , webProtocol:     "https:"                             , host:     customDomain.public    , port:          8008                                                  , certFile:       ""                                                    , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: customDomain.public }
  regions             = { kodingme: "#{configName}"                          , vagrant:            "vagrant"                             , sj:              "sj"                   , aws:             "aws"                                , premium:  "vagrant"            }
  algolia             = { appId:    'DYVV81J2S1'                             , indexSuffix:     '.sandbox'                             }
  algoliaSecret       = { appId:    algolia.appId                            , apiKey:             '303eb858050b1067bcd704d6cbfb977ci'   , indexSuffix:     algolia.indexSuffix    , apiSecretKey:    '041427512bcdcd0c7bd4899ec8175f46', apiTokenKey: "d15cab2a1bcead494e38cc33d32c4621" }
  mixpanel            = { token:    "a57181e216d9f713e19d5ce6d6fb6cb3"       , enabled:            no                                  }
  postgres            = { host:     "#{prod_simulation_server}"              , port:               5432                                  , username:        "socialapplication"    , password:        "socialapplication"                  , dbname:   "social"             }
  kontrolPostgres     = { host:     "#{prod_simulation_server}"              , port:               5432                                  , username:        "kontrolapplication"   , password:        "kontrolapplication"                 , dbname:   "social"             }
  kiteHome            = "#{projectRoot}/kite_home/koding"
  pubnub              = { publishkey: "pub-c-ed2a8027-1f8a-4070-b0ec-d4ad535435f6", subscribekey: "sub-c-00d2be66-8867-11e4-9b60-02ee2ddab7fe"  , secretkey: "sec-c-Mzg5ZTMzOTAtYjQxOC00YTc5LWJkNWEtZmI3NTk3ODA5YzAx"                                     , serverAuthKey: "689b3039-439e-4ca6-80c2-3b0b17e3f2f3b3736a37-554c-44a1-86d4-45099a98c11a"       , origin: "pubsub.pubnub.com"                              , enabled:  yes                         }
  gatekeeper          = { host:     "localhost"                                   , port:               7200                                    , pubnub: pubnub                                }
  paymentwebhook      = { port : "6600", debug : false }


  kloudPort           = 5500
  kloud               = { port : kloudPort, privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile, kontrolUrl: kontrol.url, registerUrl : "#{customDomain.public}/kloud/kite", secretKey :  "J7suqUXhqXeiLchTrBDvovoJZEBVPxncdHyHCYqnGfY4HirKCe", address : "http://localhost:#{kloudPort}/kite"}

  googleapiServiceAccount = {clientId       :  "753589381435-irpve47dabrj9sjiqqdo2k9tr8l1jn5v.apps.googleusercontent.com", clientSecret : "1iNPDf8-F9bTKmX8OWXlkYra" , serviceAccountEmail    : "753589381435-irpve47dabrj9sjiqqdo2k9tr8l1jn5v@developer.gserviceaccount.com", serviceAccountKeyFile : "#{projectRoot}/keys/googleapi-privatekey.pem"}


  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go

  segment                 = 'kb2hfdgf20'

  socialapi =
    proxyUrl                : "#{customDomain.local}/api/social"
    port                    : "7000"
    configFilePath          : "#{projectRoot}/go/src/socialapi/config/sandbox.toml"
    postgres                : postgres
    mq                      : mq
    redis                   : url: redis.url
    mongo                   : mongo
    environment             : environment
    region                  : region
    hostname                : hostname
    protocol                : protocol
    email                   : email
    sitemap                 : { redisDB: 0, updateInterval : "30m" }
    algolia                 : algoliaSecret
    mixpanel                : mixpanel
    limits                  : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: 3 }
    eventExchangeName       : "BrokerMessageBus"
    disableCaching          : no
    debug                   : yes
    stripe                  : { secretToken : "sk_test_2ix1eKPy8WtfWTLecG9mPOvN" }
    paypal                  : { username: 'senthil+1_api1.koding.com', password: 'JFH6LXW97QN588RC', signature: 'AFcWxV21C7fd0v3bYYYRCpSSRl31AjnvzeXiWRC89GOtfhnGMSsO563z', returnUrl: "#{customDomain.public}/-/payments/paypal/return", cancelUrl: "#{customDomain.public}/-/payments/paypal/cancel", isSandbox: yes }
    gatekeeper              : gatekeeper
    customDomain            : customDomain
    kloud                   : { secretKey: kloud.secretKey, address: kloud.address }
    paymentwebhook          : paymentwebhook
    googleapiServiceAccount : googleapiServiceAccount
    segment                 : segment

  userSitesDomain     = "sandbox.koding.io"
  socialQueueName     = "koding-social-#{configName}"
  logQueueName        = socialQueueName+'log'

  # do not change this for production keep it as `no`, `false`, `not true` ok? ~ GG
  autoConfirmAccounts = no

  kloudPort           = 5500

  KONFIG              =
    configName                     : configName
    environment                    : environment
    regions                        : regions
    region                         : region
    hostname                       : hostname
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
    monitoringRedis                : "10.0.0.123:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #
    vmwatcher                      : {port          : "6400"                      , awsKey    : "AKIAI6KPPX7WUT3XAYIQ"      , awsSecret         : "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"                                                      , kloudSecretKey : kloud.secretKey                      , kloudAddr : kloud.address, connectToKlient: true, debug: true, mongo: mongo, redis: redis.url }
    gowebserver                    : {port          : 6500}
    webserver                      : {port          : 8080                        , useCacheHeader: no                      , kitePort          : 8860 }
    authWorker                     : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth'      , authExchange      : "auth"                                  , authAllExchange : "authAll"                           , port  : 9530 }
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'              , run               : yes                                     , forcedRecipient : email.forcedRecipient               , maxAge: 3    , port  : 9540 }
    elasticSearch                  : {host          : "#{prod_simulation_server}" , port      : 9200                        , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                        , login     : "#{rabbitmq.login}"         , queueName         : socialQueueName                         , kitePort        : 8760 }
    email                          : email
    newkites                       : {useTLS        : no                          , certFile  : ""                          , keyFile: "#{kiteHome}/kite.key"  }
    log                            : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}
    boxproxy                       : {port          : 80 }
    sourcemaps                     : {port          : 3526 }
    appsproxy                      : {port          : 3500 }
    rerouting                      : {port          : 9500 }

    kloud                          : kloud

    emailConfirmationCheckerWorker : {enabled: no                                 , login : "#{rabbitmq.login}"             , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                           , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol
    gatekeeper                     : gatekeeper

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'             , loggedRequests: "/^(subscriptions|transactions)/"}
    sendgrid                       : sendgrid
    opsview                        : {push          : no                                             , host          : ''                                           , bin: null                                                                             , conf: null}
    github                         : {clientId      : "d3b586defd01c24bb294"                         , clientSecret  : "8eb80af7589972328022e80c02a53f3e2e39a323"}
    odesk                          : {key           : "639ec9419bc6500a64a2d5c3c29c2cf8"             , secret        : "549b7635e1e4385e"                           , request_url: "https://www.odesk.com/api/auth/v1/oauth/token/request"                  , access_url: "https://www.odesk.com/api/auth/v1/oauth/token/access" , secret_url: "https://www.odesk.com/services/api/auth?oauth_token=" , version: "1.0"                                                    , signature: "HMAC-SHA1" , redirect_uri : "#{customDomain.public}:#{customDomain.port}/-/oauth/odesk/callback"}
    facebook                       : {clientId      : "475071279247628"                              , clientSecret  : "65cc36108bb1ac71920dbd4d561aca27"           , redirectUri  : "#{customDomain.public}:#{customDomain.port}/-/oauth/facebook/callback"}
    google                         : {client_id     : "1058622748167.apps.googleusercontent.com"     , client_secret : "vlF2m9wue6JEvsrcAaQ-y9wq"                   , redirect_uri : "#{customDomain.public}:#{customDomain.port}/-/oauth/google/callback"}
    twitter                        : {key           : "aFVoHwffzThRszhMo2IQQ"                        , secret        : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E" , redirect_uri : "#{customDomain.public}:#{customDomain.port}/-/oauth/twitter/callback"   , request_url  : "https://twitter.com/oauth/request_token"           , access_url   : "https://twitter.com/oauth/access_token"            , secret_url: "https://twitter.com/oauth/authenticate?oauth_token=" , version: "1.0"         , signature: "HMAC-SHA1"}
    linkedin                       : {client_id     : "f4xbuwft59ui"                                 , client_secret : "fBWSPkARTnxdfomg"                           , redirect_uri : "#{customDomain.public}:#{customDomain.port}/-/oauth/linkedin/callback"}
    slack                          : {token         : "xoxp-2155583316-2155760004-2158149487-a72cf4" , channel       : "C024LG80K"}
    datadog                        : {api_key       : "6d3e00fb829d97cb6ee015f80063627c"             , app_key       : "c9be251621bc75acf4cd040e3edea17fff17a13a"}
    statsd                         : {use           : false                                          , ip            : "#{customDomain.public}"                       , port: 8125}
    graphite                       : {use           : false                                          , host          : "#{customDomain.public}"                       , port: 2003}
    sessionCookie                  : {maxAge        : 1000 * 60 * 60 * 24 * 14                       , secure        : no}
    logLevel                       : {neo4jfeeder   : "notice"                                       , oskite: "info"                                               , terminal: "info"                                                                      , kontrolproxy  : "notice"                                           , kontroldaemon : "notice"                                           , userpresence  : "notice"                                          , vmproxy: "notice"      , graphitefeeder: "notice"                                                           , sync: "notice" , topicModifier : "notice" , postModifier  : "notice" , router: "notice" , rerouting: "notice" , overview: "notice" , amqputil: "notice" , rabbitMQ: "notice" , ldapserver: "notice" , broker: "notice"}
    aws                            : {key           : 'AKIAJSUVKX6PD254UGAA'                         , secret        : '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'}
    embedly                        : {apiKey        : '94991069fb354d4e8fdb825e52d4134a'}
    troubleshoot                   : {recipientEmail: "can@koding.com"}
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    mixpanel                       : mixpanel.token
    recapthcha                     : '6LfZL_kSAAAAAIrbAbnMPt9ri79pyHUZ0-QqB6Iz'
    segment                        : segment
    googleapiServiceAccount        : googleapiServiceAccount
    siftScience                    : 'a41deacd57929378'
    prerenderToken                 : 'St4CU4a5hvfYCEOboftc'
    tokbox                         : { API_KEY: '45082272', API_SECRET: 'fb232a623fa9936ace8d8f9826c3e4a942d457b8' }

    collaboration :
      timeout     : 1 * 60 * 1000

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client                         : {watch: yes , version: version , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  # NOTE: when you add to runtime options below, be sure to modify
  # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`
  KONFIG.client.runtimeOptions =
    kites                : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia              : algolia
    logToExternal        : no                                 # rollbar , mixpanel etc.
    suppressLogs         : no
    logToInternal        : no                                 # log worker
    authExchange         : "auth"
    environment          : environment                        # this is where browser knows what kite environment to query for
    version              : version
    resourceName         : socialQueueName
    userSitesDomain      : userSitesDomain
    logResourceName      : logQueueName
    socialApiUri         : "/xhr"
    apiUri               : "/"
    mainUri              : "/"
    sourceMapsUri        : "/sourcemaps"
    broker               : {uri          : "/subscribe" }
    appsUri              : "/appsproxy"
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout     : 1000 * 15
    userIdleMs           : 1000 * 60 * 5
    embedly              : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    github               : {clientId     : "d3b586defd01c24bb294" }
    newkontrol           : {url          : "#{kontrol.url}"}
    sessionCookie        : {maxAge       : 1000 * 60 * 60 * 24 * 14  , secure: no   }
    troubleshoot         : {idleTime     : 1000 * 60 * 60            , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    recaptcha            : '6LfZL_kSAAAAABDrxNU5ZAQk52jx-2sJENXRFkTO'
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
    pubnub               : { subscribekey: pubnub.subscribekey , ssl: yes, enabled: yes     }
    collaboration        : KONFIG.collaboration
    paymentBlockDuration : 2 * 60 * 1000 # 2 minutes

    # NOTE: when you add to runtime options above, be sure to modify
    # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`

    # END: PROPERTIES SHARED WITH BROWSER #


  #--- RUNTIME CONFIGURATION: WORKERS AND KITES ---#
  GOBIN = "#{projectRoot}/go/bin"


   # THESE COMMANDS WILL EXECUTE IN PARALLEL.

  KONFIG.workers =
    gowebserver         :
      group             : "webserver"
      ports             :
         incoming       : "#{KONFIG.gowebserver.port}"
      supervisord       :
        command         : "#{GOBIN}/go-webserver -c #{configName}"
      nginx             :
        locations       : [
          location      : "~^/IDE/.*"
          auth          : yes
      ]
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
        command         : "#{GOBIN}/kloud -networkusageendpoint http://localhost:#{KONFIG.vmwatcher.port} -planendpoint #{socialapi.proxyUrl}/payments/subscriptions -hostedzone #{userSitesDomain} -region #{region} -environment #{environment} -port #{KONFIG.kloud.port} -publickey #{kontrol.publicKeyFile} -privatekey #{kontrol.privateKeyFile} -kontrolurl #{kontrol.url}  -registerurl #{KONFIG.kloud.registerUrl} -mongourl #{KONFIG.mongo} -prodmode=#{configName is "prod"}"
      nginx             :
        websocket       : yes
        locations       : [ location: "~^/kloud/.*" ]
      healthCheckURL    : "http://localhost:#{KONFIG.kloud.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kloud.port}/version"

    # ngrokProxy          :
    #   group             : "environment"
    #   supervisord       :
    #     command         : "coffee #{projectRoot}/ngrokProxy --user #{publicHostname}"

    broker              :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.broker.port}"
      supervisord       :
        command         : "#{GOBIN}/broker -c #{configName}"
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
        command         : "#{GOBIN}/rerouting -c #{configName}"
      healthCheckURL    : "http://localhost:#{KONFIG.rerouting.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.rerouting.port}/version"

    authworker          :
      group             : "webserver"
      instances         : 2
      supervisord       :
        command         : "node #{projectRoot}/workers/auth/index.js -c #{configName} -p #{KONFIG.authWorker.port} --disable-newrelic"
      healthCheckURL    : "http://localhost:#{KONFIG.authWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.authWorker.port}/version"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      supervisord       :
        command         : "node #{projectRoot}/servers/sourcemaps/index.js -c #{configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"

    emailsender         :
      group             : "webserver"
      supervisord       :
        command         : "node #{projectRoot}/workers/emailsender/index.js  -c #{configName} -p #{KONFIG.emailWorker.port} --disable-newrelic"
      healthCheckURL    : "http://localhost:#{KONFIG.emailWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.emailWorker.port}/version"

    appsproxy           :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.appsproxy.port}"
      supervisord       :
        command         : "node #{projectRoot}/servers/appsproxy/web.js -c #{configName} -p #{KONFIG.appsproxy.port}"

    webserver           :
      group             : "webserver"
      instances         : 2
      ports             :
        incoming        : "#{KONFIG.webserver.port}"
        outgoing        : "#{KONFIG.webserver.kitePort}"
      supervisord       :
        command         : "node #{projectRoot}/servers/index.js -c #{configName} -p #{KONFIG.webserver.port} --disable-newrelic --kite-port=#{KONFIG.webserver.kitePort} --kite-key=#{kiteHome}/kite.key"
      nginx             :
        locations       : [
          location      : "/"
          auth          : yes
        ]

    socialworker        :
      group             : "webserver"
      instances         : 2
      ports             :
        incoming        : "#{KONFIG.social.port}"
        outgoing        : "#{KONFIG.social.kitePort}"
      supervisord       :
        command         : "node #{projectRoot}/workers/social/index.js -c #{configName} -p #{KONFIG.social.port} -r #{region} --disable-newrelic --kite-port=#{KONFIG.social.kitePort} --kite-key=#{kiteHome}/kite.key"
      nginx             :
        locations       : [ location: "/xhr" ]
      healthCheckURL    : "http://localhost:#{KONFIG.social.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.social.port}/version"

    paymentwebhook      :
      group             : "socialapi"
      ports             :
        incoming        : paymentwebhook.port
      supervisord       :
        command         : "#{GOBIN}/paymentwebhook -c #{socialapi.configFilePath} -kite-init=true"
        stopwaitsecs    : 20
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
        command         : "#{GOBIN}/vmwatcher -c #{configName}"
        stopwaitsecs    : 20
      healthCheckURL    : "http://localhost:#{KONFIG.vmwatcher.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.vmwatcher.port}/version"

    # Social API workers
    socialapi           :
      group             : "socialapi"
      instances         : 2
      ports             :
        incoming        : "#{socialapi.port}"
      supervisord       :
        command         : "#{GOBIN}/api -c #{socialapi.configFilePath} -port=#{socialapi.port}"
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
            location    : "~ /api/social/search-key"
            proxyPass   : "http://socialapi/search-key$1$is_args$args"
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

    dailyemail          :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/dailyemail -c #{socialapi.configFilePath}"

    algoliaconnector    :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/algoliaconnector -c #{socialapi.configFilePath}"

    notification        :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/notification -c #{socialapi.configFilePath}"

    popularpost         :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/popularpost -c #{socialapi.configFilePath}"

    populartopic        :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/populartopic -c #{socialapi.configFilePath}"

    pinnedpost          :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/pinnedpost -c #{socialapi.configFilePath}"

    realtime            :
      group             : "socialapi"
      instances         : 3
      supervisord       :
        command         : "#{GOBIN}/realtime  -c #{socialapi.configFilePath}"

    sitemapfeeder       :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/sitemapfeeder -c #{socialapi.configFilePath}"

    sitemapgenerator    :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/sitemapgenerator -c #{socialapi.configFilePath}"

    activityemail       :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/activityemail -c #{socialapi.configFilePath}"

    topicfeed           :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/topicfeed -c #{socialapi.configFilePath}"

    trollmode           :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/trollmode -c #{socialapi.configFilePath}"

    privatemessageemailfeeder :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/privatemessageemailfeeder -c #{socialapi.configFilePath}"

    privatemessageemailsender :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/privatemessageemailsender -c #{socialapi.configFilePath}"

    collaboration :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/collaboration -kite-init -c #{socialapi.configFilePath}"

    gatekeeper          :
      group             : "socialapi"
      ports             :
        incoming        : "#{gatekeeper.port}"
      supervisord       :
        command         : "#{GOBIN}/gatekeeper -c #{socialapi.configFilePath}"
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
        command         : "#{GOBIN}/dispatcher -c #{socialapi.configFilePath}"

    mailsender          :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/emailsender -c #{socialapi.configFilePath}"

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
    id_rsa          : fs.readFileSync("./install/keys/prod.ssh/id_rsa"          , "utf8")
    id_rsa_pub      : fs.readFileSync("./install/keys/prod.ssh/id_rsa.pub"      , "utf8")
    authorized_keys : fs.readFileSync("./install/keys/prod.ssh/authorized_keys" , "utf8")
    config          : fs.readFileSync("./install/keys/prod.ssh/config"          , "utf8")

  generateRunFile = (KONFIG) ->
    return """
      #!/bin/bash
      export HOME=/home/user-ec2
      export KONFIG_JSON='#{KONFIG.JSON}'
      """

  KONFIG.ENV             = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.nginxConf       = (require "../deployment/nginx.coffee").create KONFIG, environment
  KONFIG.runFile         = generateRunFile KONFIG
  KONFIG.supervisorConf  = (require "../deployment/supervisord.coffee").create KONFIG

  return KONFIG

module.exports = Configuration
