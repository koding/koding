zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  prod_simulation_server = "10.0.0.136"

  slKeys =
    vm_kloud:
      username : "SL793093"
      apiKey   : "f2f8cf4da8618aa3c467f692af0deb22f56cfe5f49cffbc3b0611ad13e4d5a99"

  awsKeys =
    # s3 full access
    worker_terraformer:
      accessKeyId     : "AKIAICCV3GMNBL4ECN5Q"
      secretAccessKey : "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"

    # s3 put only to koding-client bucket
    worker_koding_client_s3_put_only:
      accessKeyId     : "AKIAJCUG42THBT4LBQEQ"
      secretAccessKey : "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"

    # admin
    worker_test:
      accessKeyId     : "AKIAIQESD65KKYRYAWDA"
      secretAccessKey : "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"

    # s3 put only
    worker_test_data_exporter:
      accessKeyId     : "AKIAIWO4ZPTLQEYSOLGA"
      secretAccessKey : "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"

    # AmazonRDSReadOnlyAccess
    worker_rds_log_parser:
      accessKeyId     : "AKIAJX6IPI3PQCS3GJ6Q"
      secretAccessKey : "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"

    # ELB & EC2 -> AmazonEC2ReadOnlyAccess
    worker_multi_ssh:
      accessKeyId     : "AKIAI7CKP5SNHCBUEDXQ"
      secretAccessKey : "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"

    # AmazonEC2FullAccess
    worker_test_instance_launcher:
      accessKeyId     : "AKIAJDR2J6W5AT4KWS4A"
      secretAccessKey : "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"

    # CloudWatchReadOnlyAccess
    vm_vmwatcher:     # vm_vmwatcher_dev
      accessKeyId     : "AKIAJ3OZKOIQUTV2GCBQ"
      secretAccessKey : "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"

    # KloudPolicy
    vm_kloud:         # vm_kloud_dev
      accessKeyId     : "AKIAJRNT55RTV2MHD4VA"
      secretAccessKey : "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"

    # TunnelProxyPolicy
    worker_tunnelproxymanager: # Name worker_tunnelproxymanager_dev
      accessKeyId     : "AKIAIM3GAPJAIWTFZOJQ"
      secretAccessKey : "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"

  publicPort     = options.publicPort          = "80"
  hostname       = options.hostname            = "sandbox.koding.com#{if publicPort is "80" then "" else ":"+publicPort}"
  protocol       = options.protocol            or "https:"
  publicHostname = options.publicHostname      = "#{protocol}//#{hostname}"
  region         = options.region              = "aws"
  configName     = options.configName          = "sandbox"
  environment    = options.environment         = "sandbox"
  projectRoot    = options.projectRoot         or "/opt/koding"
  version        = options.tag
  tag            = options.tag
  publicIP       = options.publicIP            or "*"
  githubapi      =
    debug        : no
    timeout      : 5000
    userAgent    : 'Koding-Bridge'

  mongo               = "#{prod_simulation_server}:27017/koding"
  etcd                = "#{prod_simulation_server}:4001"

  redis               = { host:     "#{prod_simulation_server}"              , port:               6379                                  , db:              0                    }
  redis.url           = "#{redis.host}:#{redis.port}"

  rabbitmq            = { host:     "#{prod_simulation_server}"              , port:               5672                                  , apiPort:         15672                  , login:           "guest"                              , password: "guest"                , vhost:         "/"                                                 }
  mq                  = { host:     "#{rabbitmq.host}"                       , port:               rabbitmq.port                         , apiAddress:      "#{rabbitmq.host}"     , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"    , componentUser: "#{rabbitmq.login}"                                   , password:       "#{rabbitmq.password}"                                , heartbeat:      10           , vhost:        "#{rabbitmq.vhost}" }
  customDomain        = { public:   "https://#{hostname}"                    , public_:            "#{hostname}"                         , local:           "http://127.0.0.1"     , local_:          "127.0.0.1"                          , port:     80                     , host: hostname }
  email               = { host:     "#{customDomain.public_}"                , defaultFromMail:    'hello@koding.com'                    , defaultFromName: 'Koding'               , forcedRecipientEmail: null                            , forcedRecipientUsername: null }
  kontrol             = { url:      "#{options.publicHostname}/kontrol/kite" , port:               3000                                  , useTLS:          no                     , certFile:        ""                                   , keyFile:  ""                     , publicKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_private.pem"}
  broker              = { name:     "broker"                                 , serviceGenericName: "broker"                              , ip:              ""                     , webProtocol:     "https:"                             , host:     customDomain.public    , port:          8008                                                  , certFile:       ""                                                    , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: customDomain.public }
  regions             = { kodingme: "#{configName}"                          , vagrant:            "vagrant"                             , sj:              "sj"                   , aws:             "aws"                                , premium:  "vagrant"            }
  algolia             = { appId:    'DYVV81J2S1'                             , indexSuffix:        '.sandbox'                             }
  algoliaSecret       = { appId:    algolia.appId                            , indexSuffix:        algolia.indexSuffix                   , apiSecretKey:    '682e02a34e2a65dc774f5ec355ceca33'                                             , apiSearchOnlyKey: "8dc0b0dc39282effe9305981d427fec7" }
  postgres            = { host:     "#{prod_simulation_server}"              , port:               "5432"                                , username:        "socialapp201506"      , password:        "socialapp201506"                    , dbname:   "social"             }
  kontrolPostgres     = { host:     "#{prod_simulation_server}"              , port:               5432                                  , username:        "kontrolapp201506"     , password:        "kontrolapp201506"                   , dbname:   "social"             , connecttimeout: 20 }
  kiteHome            = "#{projectRoot}/kite_home/koding"
  pubnub              = { publishkey: "pub-c-5b987056-ef0f-457a-aadf-87b0488c1da1", subscribekey:       "sub-c-70ab5d36-0b13-11e5-8104-0619f8945a4f"  , secretkey: "sec-c-MWFhYTAzZWUtYzg4My00ZjAyLThiODEtZmI0OTFkOTk0YTE0"                , serverAuthKey: "46fae3cc-9344-4edb-b152-864ba567980c7960b1d8-31dd-4722-b0a1-59bf878bd551"                , origin: "pubsub.pubnub.com"                              , enabled:  yes                         }
  gatekeeper          = { host:     "localhost"                                   , port:               "7200"                                        , pubnub: pubnub                                }
  integration         = { host:     "localhost"                                   , port:               "7300"                                        , url: "#{customDomain.public}/api/integration" }
  webhookMiddleware   = { host:     "localhost"                                   , port:               "7350"                                        , url: "#{customDomain.public}/api/webhook"     }
  paymentwebhook      = { port:     "6600"                                        , debug:              false                                         , secretKey: "paymentwebhooksecretkey-sandbox"  }
  tokbox              = { apiKey:   "45253342"                                    , apiSecret:          "e834f7f61bd2b3fafc36d258da92413cebb5ce6e" }
  recaptcha           = { enabled:  yes }



  kloudPort           = 5500
  kloud               = { port : kloudPort, userPrivateKeyFile: "./certs/kloud/dev/kloud_dev_rsa.pem", userPublicKeyfile: "./certs/kloud/dev/kloud_dev_rsa.pub", privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile, kontrolUrl: kontrol.url, registerUrl : "#{customDomain.public}/kloud/kite", secretKey :  "J7suqUXhqXeiLchTrBDvovoJZEBVPxncdHyHCYqnGfY4HirKCe", address : "http://localhost:#{kloudPort}/kite"}
  terraformer         = { port : 2300     , bucket         : "koding-terraformer-state-#{configName}"  ,    localstorepath:  "#{projectRoot}/go/data/terraformer"  }

  googleapiServiceAccount =
    clientId              : "1044469742845-kaqlodvc8me89f5r6ljfjvp5deku4ee0.apps.googleusercontent.com"
    clientSecret          : "8-gOw1ckGNW2bDgdxPHGdQh7"
    serviceAccountEmail   : "1044469742845-kaqlodvc8me89f5r6ljfjvp5deku4ee0@developer.gserviceaccount.com"
    serviceAccountKeyFile : "#{projectRoot}/keys/KodingCollaborationDev201506.pem"


  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go

  segment = 'swZaC1nE4sYPLjkGTKsNpmGAkYmPcFtx'

  disabledFeatures =
    moderation : yes
    teams      : yes
    botchannel : yes

  github =
    clientId      : "d3b586defd01c24bb294"
    clientSecret  : "8eb80af7589972328022e80c02a53f3e2e39a323"
    redirectUri   : "https://sandbox.koding.com/-/oauth/github/callback"

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
    limits                  : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: 3 }
    eventExchangeName       : "BrokerMessageBus"
    disableCaching          : no
    debug                   : no
    stripe                  : { secretToken : "sk_test_LLE4fVGK2zY3By3gccUYCLCw" }
    paypal                  : { username: 'senthil+1_api1.koding.com', password: 'EUUPDYXX5EBZFGPN', signature: 'APp0PS-Ty0EAKx39nQi9zq9l6qgIAWb9YAF9AgXPK4-XeR7EAeeJSvnM', returnUrl: "#{customDomain.public}/-/payments/paypal/return", cancelUrl: "#{customDomain.public}/-/payments/paypal/cancel", isSandbox: yes }
    gatekeeper              : gatekeeper
    integration             : integration
    webhookMiddleware       : webhookMiddleware
    customDomain            : customDomain
    kloud                   : { secretKey: kloud.secretKey, address: kloud.address }
    paymentwebhook          : paymentwebhook
    googleapiServiceAccount : googleapiServiceAccount
    geoipdbpath             : "#{projectRoot}/go/data/geoipdb"
    segment                 : segment
    disabledFeatures        : disabledFeatures
    janitor                 : { port: "6700", secretKey: "janitorsecretkey-sandbox" }
    github                  : github

  userSitesDomain     = "sandbox.koding.io"
  hubspotPageURL      = "https://teams-koding.hs-sites.com"

  socialQueueName     = "koding-social-#{configName}"

  # do not change this for production keep it as `no`, `false`, `not true` ok? ~ GG
  autoConfirmAccounts = no

  kloudPort           = 5500

  tunnelserver =
    port            : 80
    basevirtualhost : "koding.me"
    hostedzone      : "koding.me"

  KONFIG              =
    configName                     : configName
    environment                    : environment
    ebEnvName                      : options.ebEnvName
    runGoWatcher                   : options.runGoWatcher
    regions                        : regions
    region                         : region
    hostname                       : hostname
    protocol                       : protocol
    publicPort                     : publicPort
    publicHostname                 : publicHostname
    version                        : version
    awsKeys                        : awsKeys
    broker                         : broker
    uri                            : address: customDomain.public
    userSitesDomain                : userSitesDomain
    hubspotPageURL                 : hubspotPageURL
    autoConfirmAccounts            : autoConfirmAccounts
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    kiteHome                       : kiteHome
    redis                          : redis.url
    monitoringRedis                : "#{prod_simulation_server}:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}
    githubapi                      : githubapi
    recaptcha                      : {enabled : recaptcha.enabled  , url : "https://www.google.com/recaptcha/api/siteverify", secret : "6Ld8wwkTAAAAAJoSJ07Q_6ysjQ54q9sJwC5w4xP_" }

    # -- WORKER CONFIGURATION -- #
    vmwatcher                      : {port          : "6400"                      , awsKey    : awsKeys.vm_vmwatcher.accessKeyId     , awsSecret : awsKeys.vm_vmwatcher.secretAccessKey   , kloudSecretKey : kloud.secretKey , kloudAddr : kloud.address, connectToKlient: true, debug: false, mongo: mongo, redis: redis.url, secretKey: "vmwatchersecretkey-sandbox" }
    gowebserver                    : {port          : 6500}
    gatheringestor                 : {port          : 6800}
    webserver                      : {port          : 8080                        , useCacheHeader: no                      , kitePort          : 8860 }
    authWorker                     : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth'      , authExchange      : "auth"                                  , authAllExchange : "authAll"                           , port  : 9530 }
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'              , run               : yes                                     , forcedRecipientEmail : email.forcedRecipientEmail         , forcedRecipientUsername : email.forcedRecipientUsername               , maxAge: 3    , port  : 9540 }
    elasticSearch                  : {host          : "#{prod_simulation_server}" , port      : 9200                        , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                        , login     : "#{rabbitmq.login}"         , queueName         : socialQueueName                         , kitePort        : 8760 }
    email                          : email
    newkites                       : {useTLS        : no                          , certFile  : ""                          , keyFile: "#{kiteHome}/kite.key"  }
    boxproxy                       : {port          : 80 }
    sourcemaps                     : {port          : 3526 }
    rerouting                      : {port          : 9500 }

    kloud                          : kloud
    terraformer                    : terraformer

    emailConfirmationCheckerWorker : {enabled: no                                 , login : "#{rabbitmq.login}"             , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                           , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol
    gatekeeper                     : gatekeeper

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'             , loggedRequests: "/^(subscriptions|transactions)/"}
    opsview                        : {push          : no                                             , host          : ''                                           , bin: null                                                                             , conf: null}
    github                         : github
    odesk                          : {key           : "7872edfe51d905c0d1bde1040dd33c1a"             , secret        : "746e22f34ca4546e"                           , request_url: "https://www.odesk.com/api/auth/v1/oauth/token/request"                  , access_url: "https://www.odesk.com/api/auth/v1/oauth/token/access" , secret_url: "https://www.odesk.com/services/api/auth?oauth_token=" , version: "1.0"                                                    , signature: "HMAC-SHA1" , redirect_uri : "https://sandbox.koding.com/-/oauth/odesk/callback"}
    facebook                       : {clientId      : "650676665033389"                              , clientSecret  : "6771ee1f5aa28e5cd13d3465bacffbdc"           , redirectUri  : "https://sandbox.koding.com/-/oauth/facebook/callback"}
    google                         : {client_id     : "569190240880-d40t0cmjsu1lkenbqbhn5d16uu9ai49s.apps.googleusercontent.com"                                    , client_secret : "9eqjhOUgnjOOjXxfn6bVzXz-"                                            , redirect_uri : "https://sandbox.koding.com/-/oauth/google/callback" }
    twitter                        : {key           : "2RXF9BaTlYbDyRS3DPOrfBJzR"                    , secret        : "KrmmizYhEhu1zd1r0y6sn1XlW9mc1EGZYiqRbBMNQWC1MCarbc" , redirect_uri : "https://sandbox.koding.com/-/oauth/twitter/callback"   , request_url  : "https://twitter.com/oauth/request_token"           , access_url   : "https://twitter.com/oauth/access_token"            , secret_url: "https://twitter.com/oauth/authenticate?oauth_token=" , version: "1.0"         , signature: "HMAC-SHA1"}
    linkedin                       : {client_id     : "7523x9y261cw0v"                               , client_secret : "VBpMs6tEfs3peYwa"                           , redirect_uri : "https://sandbox.koding.com/-/oauth/linkedin/callback"}
    datadog                        : {api_key       : "1daadb1d4e69d1ae0006b73d404e527b"             , app_key       : "aecf805ae46ec49bdd75e8866e61e382918e2ee5"}
    sessionCookie                  : {maxAge        : 1000 * 60 * 60 * 24 * 14                       , secure        : no}
    aws                            : {key           : ''                                             , secret        : ''}
    embedly                        : {apiKey        : '537d6a2471864e80b91d9f4a78384873'}
    iframely                       : {apiKey        : "157f8f72ac846689f47865"                       , url           : 'http://iframe.ly/api/oembed'}
    troubleshoot                   : {recipientEmail: "can@koding.com"}
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    segment                        : segment
    googleapiServiceAccount        : googleapiServiceAccount
    siftScience                    : '2b62c0cbea188dc6'
    prerenderToken                 : 'rmhVl6TMAbAO4GQJyAI3'
    tokbox                         : tokbox
    disabledFeatures               : disabledFeatures
    contentRotatorUrl              : 'http://koding.github.io'
    collaboration                  : {timeout: 1 * 60 * 1000}
    client                         : {watch: yes                                                     , version: version                                             , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}
    jwt                            : {secret: "ac25b4e6009c1b6ba336a3eb17fbc3b7"                     , confirmExpiresInMinutes: 10080  } # 7 days
    sendEventsToSegment            : options.sendEventsToSegment

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  # NOTE: when you add to runtime options below, be sure to modify
  # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`
  KONFIG.client.runtimeOptions =
    kites                : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia              : algolia
    suppressLogs         : no
    authExchange         : "auth"
    environment          : environment                        # this is where browser knows what kite environment to query for
    version              : version
    resourceName         : socialQueueName
    userSitesDomain      : userSitesDomain
    socialApiUri         : "/xhr"
    apiUri               : "/"
    mainUri              : "/"
    sourceMapsUri        : "/sourcemaps"
    broker               : {uri          : "/subscribe" }
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout     : 1000 * 15
    userIdleMs           : 1000 * 60 * 5
    embedly              : {apiKey       : KONFIG.embedly.apiKey}
    github               : {clientId     : github.clientId }
    newkontrol           : {url          : "#{kontrol.url}"}
    sessionCookie        : KONFIG.sessionCookie
    troubleshoot         : {idleTime     : 1000 * 60 * 60            , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    stripe               : { token: 'pk_test_2x9UxMl1EBdFtwT5BRfOHxtN' }
    externalProfiles     :
      google             : {nicename: 'Google'  }
      linkedin           : {nicename: 'LinkedIn'}
      twitter            : {nicename: 'Twitter' }
      odesk              : {nicename: 'oDesk'   , urlLocation: 'info.profile_url' }
      facebook           : {nicename: 'Facebook', urlLocation: 'link'             }
      github             : {nicename: 'GitHub'  , urlLocation: 'html_url'         }
    entryPoint           : {slug:'koding'       , type:'group'}
    siftScience          : '91f469711c'
    paypal               : { formUrl: 'https://www.sandbox.paypal.com/incontext' }
    pubnub               : { subscribekey: pubnub.subscribekey , ssl: yes, enabled: yes     }
    collaboration        : KONFIG.collaboration
    paymentBlockDuration : 2 * 60 * 1000 # 2 minutes
    tokbox               : { apiKey: tokbox.apiKey }
    disabledFeatures     : disabledFeatures
    contentRotatorUrl    : 'http://koding.github.io'
    integration          : { url: "#{integration.url}" }
    webhookMiddleware    : { url: "#{webhookMiddleware.url}" }
    google               : apiKey: 'AIzaSyDiLjJIdZcXvSnIwTGIg0kZ8qGO3QyNnpo'
    recaptcha            : { enabled : recaptcha.enabled, key : "6Ld8wwkTAAAAAArpF62KStLaMgiZvE69xY-5G6ax"}
    sendEventsToSegment  : KONFIG.sendEventsToSegment

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
        command         : "#{GOBIN}/kontrol -region #{region} -machines #{etcd} -environment #{environment} -mongourl #{KONFIG.mongo} -port #{kontrol.port} -privatekey #{kontrol.privateKeyFile} -publickey #{kontrol.publicKeyFile} -storage postgres -postgres-dbname #{kontrolPostgres.dbname} -postgres-host #{kontrolPostgres.host} -postgres-port #{kontrolPostgres.port} -postgres-username #{kontrolPostgres.username} -postgres-password #{kontrolPostgres.password} -postgres-connecttimeout #{kontrolPostgres.connecttimeout}"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~^/kontrol/(.*)"
            proxyPass   : "http://kontrol/$1$is_args$args"
          }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.kontrol.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kontrol.port}/version"

    kloud               :
      group             : "environment"
      ports             :
        incoming        : "#{KONFIG.kloud.port}"
      supervisord       :
        command         : "#{GOBIN}/kloud -networkusageendpoint http://localhost:#{KONFIG.vmwatcher.port} -planendpoint #{socialapi.proxyUrl}/payments/subscriptions -hostedzone #{userSitesDomain} -region #{region} -environment #{environment} -port #{KONFIG.kloud.port} -userprivatekey #{KONFIG.kloud.userPrivateKeyFile} -userpublickey #{KONFIG.kloud.userPublicKeyfile} -publickey #{kontrol.publicKeyFile} -privatekey #{kontrol.privateKeyFile} -kontrolurl #{kontrol.url}  -registerurl #{KONFIG.kloud.registerUrl} -mongourl #{KONFIG.mongo} -prodmode=#{configName is "prod"} -awsaccesskeyid=#{awsKeys.vm_kloud.accessKeyId} -awssecretaccesskey=#{awsKeys.vm_kloud.secretAccessKey} -slusername=#{slKeys.vm_kloud.username} -slapikey=#{slKeys.vm_kloud.apiKey} -janitorsecretkey=#{socialapi.janitor.secretKey} -vmwatchersecretkey=#{KONFIG.vmwatcher.secretKey} -paymentwebhooksecretkey=#{paymentwebhook.secretKey}"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~^/kloud/(.*)"
            proxyPass   : "http://kloud/$1$is_args$args"
          }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.kloud.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kloud.port}/version"

    terraformer         :
      group             : "environment"
      supervisord       :
        command         : "#{GOBIN}/terraformer -port #{KONFIG.terraformer.port} -region #{region} -environment  #{environment} -aws-key #{awsKeys.worker_terraformer.accessKeyId} -aws-secret #{awsKeys.worker_terraformer.secretAccessKey} -aws-bucket #{KONFIG.terraformer.bucket} -localstorepath #{KONFIG.terraformer.localstorepath}"
      healthCheckURL    : "http://localhost:#{KONFIG.terraformer.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.terraformer.port}/version"

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
      supervisord       :
        command         : "node #{projectRoot}/workers/auth/index.js -c #{configName} -p #{KONFIG.authWorker.port} --disable-newrelic"
      healthCheckURL    : "http://localhost:#{KONFIG.authWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.authWorker.port}/version"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      nginx             :
        locations       : [ { location : "/sourcemaps" } ]
      supervisord       :
        command         : "node #{projectRoot}/servers/sourcemaps/index.js -c #{configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"

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
          {
            location    : "~ /-/api/(.*)"
            proxyPass   : "http://webserver/-/api/$1$is_args$args"
          }
          {
            location    : "/"
            auth        : yes
          }
        ]

    socialworker        :
      group             : "webserver"
      instances         : 4
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
      nginx             :
        locations       : [ { location: "/vmwatcher" } ]
      supervisord       :
        command         : "#{GOBIN}/vmwatcher -c #{configName}"
        stopwaitsecs    : 20
      healthCheckURL    : "http://localhost:#{KONFIG.vmwatcher.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.vmwatcher.port}/version"

    janitor             :
      group             : "environment"
      instances         : 1
      supervisord       :
        command         : "#{GOBIN}/janitor -c #{socialapi.configFilePath} -kite-init=true"
      healthCheckURL    : "http://localhost:#{socialapi.janitor.port}/healthCheck"
      versionURL        : "http://localhost:#{socialapi.janitor.port}/version"

    # clientWatcher       :
    #   group             : "webserver"
    #   supervisord       :
    #     command         : "ulimit -n 1024 && coffee #{projectRoot}/build-client.coffee  --watch --sourceMapsUri /sourcemaps --verbose true"

    gatheringestor      :
      ports             :
        incoming        : KONFIG.gatheringestor.port
      group             : "environment"
      instances         : 1
      supervisord       :
        command         : "#{GOBIN}/gatheringestor -c #{configName}"
        stopwaitsecs    : 20
      healthCheckURL    : "http://localhost:#{KONFIG.gatheringestor.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.gatheringestor.port}/version"
      nginx             :
        locations       : [
          location      : "~ /-/ingestor/(.*)"
          proxyPass     : "http://gatheringestor/$1$is_args$args"
        ]

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
            location    : "~ /api/social/channel/(.*)/list"
            proxyPass   : "http://socialapi/channel/$1/list$is_args$args"
          }
          {
            location    : "~ /api/social/channel/by/(.*)"
            proxyPass   : "http://socialapi/channel/by/$1$is_args$args"
          }
          {
            location    : "~ /api/social/channel/(.*)/notificationsetting"
            proxyPass   : "http://socialapi/channel/$1/notificationsetting$is_args$args"
          }
          {
            location    : "~ /api/social/notificationsetting/(.*)"
            proxyPass   : "http://socialapi/notificationsetting/$1$is_args$args"
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
            location    : "~ /api/social/sshkey"
            proxyPass   : "http://socialapi/sshkey$1$is_args$args"
          }
          {
            location    : "~ /api/social/moderation/(.*)"
            proxyPass   : "http://socialapi/moderation/$1$is_args$args"
          }
          {
            location    : "~ /api/social/account/channels"
            proxyPass   : "http://socialapi/account/channels$is_args$args"
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

    dailyemailnotifier  :
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

    topicmoderation     :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/topicmoderation -c #{socialapi.configFilePath}"

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

    team                :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/team -c #{socialapi.configFilePath}"

    integration         :
      group             : "socialapi"
      ports             :
        incoming        : "#{integration.port}"
      supervisord       :
        command         : "#{GOBIN}/webhook -c #{socialapi.configFilePath}"
      healthCheckURL    : "#{customDomain.local}/api/integration/healthCheck"
      versionURL        : "#{customDomain.local}/api/integration/version"
      nginx             :
        locations       : [
          location      : "~ /api/integration/(.*)"
          proxyPass     : "http://integration/$1$is_args$args"
        ]

    webhook             :
      group             : "socialapi"
      ports             :
        incoming        : "#{webhookMiddleware.port}"
      supervisord       :
        command         : "#{GOBIN}/webhookmiddleware -c #{socialapi.configFilePath}"
      healthCheckURL    : "#{customDomain.local}/api/webhook/healthCheck"
      versionURL        : "#{customDomain.local}/api/webhook/version"
      nginx             :
        locations       : [
          location      : "~ /api/webhook/(.*)"
          proxyPass     : "http://webhook/$1$is_args$args"
        ]

    eventsender         :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/eventsender -c #{socialapi.configFilePath}"

    contentrotator      :
      group             : "webserver"
      nginx             :
        locations       : [
          {
            location    : "~ /-/content-rotator/(.*)"
            proxyPass   : "#{KONFIG.contentRotatorUrl}/content-rotator/$1"
            extraParams : [ "resolver 8.8.8.8;" ]
          }
        ]

    tunnelproxymanager  :
      group             : "proxy"
      supervisord       :
        command         : "#{GOBIN}/tunnelproxymanager -ebenvname #{options.ebEnvName} -accesskeyid #{awsKeys.worker_tunnelproxymanager.accessKeyId} -secretaccesskey #{awsKeys.worker_tunnelproxymanager.secretAccessKey} -hostedzone-name devtunnelproxy.koding.com -hostedzone-callerreference devtunnelproxy_hosted_zone_v0"

    tunnelserver        :
      group             : "proxy"
      supervisord       :
        command         : "#{GOBIN}/tunnelserver -accesskey #{awsKeys.worker_tunnelproxymanager.accessKeyId} -secretkey #{awsKeys.worker_tunnelproxymanager.secretAccessKey} -port #{tunnelserver.port} -basevirtualhost #{tunnelserver.basevirtualhost} -hostedzone #{tunnelserver.hostedzone}"
      ports             :
        incoming        : "#{tunnelserver.port}"
      healthCheckURL    : "http://tunnelserver/healthCheck"
      versionURL        : "http://tunnelserver/version"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~ /tunnelserver/(.*)"
            proxyPass   : "http://tunnelserver/$1"
          }
        ]

    userproxies         :
      group             : "proxy"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : '~ ^\\/-\\/userproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : '~ ^\\/-\\/prodproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : '~ ^\\/-\\/sandboxproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : '~ ^\\/-\\/latestproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : '~ ^\\/-\\/devproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
        ]


  KONFIG.supervisord =
    logdir   : '/var/log/koding'
    rundir   : '/var/run'
    minfds   : 10000
    minprocs : 200

  KONFIG.supervisord.unix_http_server =
    file : "#{KONFIG.supervisord.rundir}/supervisor.sock"

  KONFIG.supervisord.memmon =
    limit : '1536MB'
    email : 'sysops+supervisord-sandbox@koding.com'


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

  generateRunFile = (KONFIG) ->
    return """
      #!/bin/bash
      export HOME=/home/ec2-user
      export KONFIG_JSON='#{KONFIG.JSON}'

      function runuserimporter () {
        node scripts/user-importer -c dev
      }

      if [ "$1" == "runuserimporter" ]; then
        runuserimporter
      fi
      """

  KONFIG.ENV             = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.nginxConf       = (require "../deployment/nginx.coffee").create KONFIG, environment
  KONFIG.runFile         = generateRunFile KONFIG
  KONFIG.supervisorConf  = (require "../deployment/supervisord.coffee").create KONFIG

  KONFIG.configCheckExempt = ["ngrokProxy", "command", "output_path"]

  return KONFIG

module.exports = Configuration
