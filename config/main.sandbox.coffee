traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  prod_simulation_server = "10.0.0.136"

  domains =
    base  : 'koding.com'
    mail  : 'koding.com'
    main  : 'sandbox.koding.com'
    port  : '80'

  defaultEmail = "hello@#{domains.mail}"

  slKeys       =
    vm_kloud   :
      username : "IBM839677"
      apiKey   : "1664173c843a22d223247837da5cab6d4de7d06f238606e1523458d59eca72d0"

  dev_master =
    accessKeyId      : "AKIAIKQZE7JIXVGIT2MA"
    secretAccessKey  : "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"




  worker_ci_test = require './aws/worker_ci_test_key.json'

  awsKeys =
    # s3 full access
    worker_terraformer: dev_master

    # s3 put only to koding-client bucket
    worker_koding_client_s3_put_only: dev_master

    # admin
    worker_test: dev_master

    # s3 put only
    worker_test_data_exporter: dev_master

    # AmazonRDSReadOnlyAccess
    worker_rds_log_parser: dev_master

    # ELB & EC2 -> AmazonEC2ReadOnlyAccess
    worker_multi_ssh: dev_master

    # AmazonEC2FullAccess
    worker_test_instance_launcher: dev_master

    # CloudWatchReadOnlyAccess
    vm_vmwatcher:     # vm_vmwatcher_dev
      accessKeyId     : "AKIAJ3OZKOIQUTV2GCBQ"
      secretAccessKey : "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"

    # KloudPolicy
    vm_kloud:         # vm_kloud_dev
      accessKeyId     : "AKIAJRNT55RTV2MHD4VA"
      secretAccessKey : "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"

    # TunnelProxyPolicy
    worker_tunnelproxymanager: dev_master # Name worker_tunnelproxymanager_dev

    #Encryption and Storage on S3
    worker_sneakerS3 : dev_master



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
  tunnelUrl      = options.tunnelUrl           or "http://devtunnelproxy.koding.com"
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
  kloud               = { port : kloudPort, userPrivateKeyFile: "./certs/kloud/dev/kloud_dev_rsa.pem", userPublicKeyfile: "./certs/kloud/dev/kloud_dev_rsa.pub", privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile, kontrolUrl: kontrol.url, registerUrl : "#{customDomain.public}/kloud/kite", secretKey :  "J7suqUXhqXeiLchTrBDvovoJZEBVPxncdHyHCYqnGfY4HirKCe", address : "http://localhost:#{kloudPort}/kite", tunnelUrl : "#{tunnelUrl}"}
  terraformer         = { port : 2300     , bucket         : "kodingdev-terraformer-state-#{configName}"  ,    localstorepath:  "#{projectRoot}/go/data/terraformer"  }

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

  mailgun =
    domain        : "koding.com"
    privateKey    : "key-6d4a0c191866434bf958aed924512758"
    publicKey     : "pubkey-dabf6c392b39cce9bce12e9a582ad051"
    unsubscribeURL: "https://api.mailgun.net/v3/koding.com/unsubscribes"

  slack  =
    clientId          : "2155583316.22364273143"
    clientSecret      : "6ee269042087643b311214d2dc3527e4"
    redirectUri       : "https://sandbox.koding.com/api/social/slack/oauth/callback"
    verificationToken : "AAeDdo5fWOcOTux88e939dXN"

  sneakerS3 =
    awsSecretAccessKey  : "#{awsKeys.worker_sneakerS3.secretAccessKey}"
    awsAccessKeyId      : "#{awsKeys.worker_sneakerS3.accessKeyId}"
    sneakerS3Path       : "s3://kodingdev-credential/"
    sneakerMasterKey    : "fecea2c8-e569-4d87-9179-8e7c93253072"
    awsRegion           : "us-east-1"

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
    slack                   : slack
    sneakerS3               : sneakerS3
    mailgun                 : mailgun


  userSitesDomain     = "sandbox.koding.io"
  hubspotPageURL      = "http://www.koding.com"

  socialQueueName     = "koding-social-#{configName}"

  # do not change this for production keep it as `no`, `false`, `not true` ok? ~ GG
  autoConfirmAccounts = no

  kloudPort           = 5500

  tunnelserver =
    port            : 80
    basevirtualhost : "koding.me"
    hostedzone      : "koding.me"

  KONFIG =
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
    tunnelserver                   : tunnelserver
    userSitesDomain                : userSitesDomain
    hubspotPageURL                 : hubspotPageURL
    autoConfirmAccounts            : autoConfirmAccounts
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    kiteHome                       : kiteHome
    redis                          : redis.url
    monitoringRedis                : "#{prod_simulation_server}:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , debugConnectionErrors: yes}
    githubapi                      : githubapi
    recaptcha                      : {enabled : recaptcha.enabled  , url : "https://www.google.com/recaptcha/api/siteverify", secret : "6Ld8wwkTAAAAAJoSJ07Q_6ysjQ54q9sJwC5w4xP_" }
    # TODO: average request count per hour for a user should be measured and a reasonable limit should be set
    nodejsRateLimiter              : {enabled : no, guestRules : [{ interval: 3600, limit: 5000 }], userRules : [{ interval: 3600, limit: 10000 }]} # limit: request limit per rate limit window, interval: rate limit window duration in seconds

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
    kontrol                        : kontrol
    newkontrol                     : kontrol
    gatekeeper                     : gatekeeper

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'             , loggedRequests: "/^(subscriptions|transactions)/"}
    opsview                        : {push          : no                                             , host          : ''                                           , bin: null                                                                             , conf: null}
    github                         : github
    slack                          : slack
    sneakerS3                      : sneakerS3
    odesk                          : {key           : "7872edfe51d905c0d1bde1040dd33c1a"             , secret        : "746e22f34ca4546e"                           , request_url: "https://www.upwork.com/api/auth/v1/oauth/token/request"                 , access_url: "https://www.upwork.com/api/auth/v1/oauth/token/access" , secret_url: "https://www.upwork.com/services/api/auth?oauth_token=" , version: "1.0"                                                    , signature: "HMAC-SHA1" , redirect_uri : "https://sandbox.koding.com/-/oauth/odesk/callback"}
    facebook                       : {clientId      : "650676665033389"                              , clientSecret  : "6771ee1f5aa28e5cd13d3465bacffbdc"           , redirectUri  : "https://sandbox.koding.com/-/oauth/facebook/callback"}
    google                         : {client_id     : "569190240880-d40t0cmjsu1lkenbqbhn5d16uu9ai49s.apps.googleusercontent.com"                                    , client_secret : "9eqjhOUgnjOOjXxfn6bVzXz-"                                            , redirect_uri : "https://sandbox.koding.com/-/oauth/google/callback" }
    twitter                        : {key           : "2RXF9BaTlYbDyRS3DPOrfBJzR"                    , secret        : "KrmmizYhEhu1zd1r0y6sn1XlW9mc1EGZYiqRbBMNQWC1MCarbc" , redirect_uri : "https://sandbox.koding.com/-/oauth/twitter/callback"   , request_url  : "https://twitter.com/oauth/request_token"           , access_url   : "https://twitter.com/oauth/access_token"            , secret_url: "https://twitter.com/oauth/authenticate?oauth_token=" , version: "1.0"         , signature: "HMAC-SHA1"}
    linkedin                       : {client_id     : "7523x9y261cw0v"                               , client_secret : "VBpMs6tEfs3peYwa"                           , redirect_uri : "https://sandbox.koding.com/-/oauth/linkedin/callback"}
    datadog                        : {api_key       : "1daadb1d4e69d1ae0006b73d404e527b"             , app_key       : "aecf805ae46ec49bdd75e8866e61e382918e2ee5"}
    sessionCookie                  : {maxAge        : 1000 * 60 * 60 * 24 * 14                       , secure        : yes}
    aws                            : {key           : ''                                             , secret        : ''}
    embedly                        : {apiKey        : '537d6a2471864e80b91d9f4a78384873'}
    iframely                       : {apiKey        : "157f8f72ac846689f47865"                       , url           : 'http://iframe.ly/api/oembed'}
    troubleshoot                   : {recipientEmail: "can@koding.com"}
    rollbar                        : "71c25e4dc728431b88f82bd3e7a600c9"
    segment                        : segment
    googleapiServiceAccount        : googleapiServiceAccount
    siftScience                    : '2b62c0cbea188dc6'
    tokbox                         : tokbox
    disabledFeatures               : disabledFeatures
    contentRotatorUrl              : 'http://koding.github.io'
    collaboration                  : {timeout: 1 * 60 * 1000}
    client                         : {watch: yes                                                     , version: version                                             , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}
    jwt                            : {secret: "ac25b4e6009c1b6ba336a3eb17fbc3b7"                     , confirmExpiresInMinutes: 10080  } # 7 days
    papertrail                     : {destination: 'logs3.papertrailapp.com:13734'                   , groupId: 2199093                                             , token: '4p4KML0UeU4ijb0swx' }
    sendEventsToSegment            : options.sendEventsToSegment
    mailgun                        : mailgun
    helpscout                      : {apiKey: 'b041e4da61c0934cb73d47e1626098430738b049'             , baseUrl: 'https://api.helpscout.net/v1'}
    domains                        : domains

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
      odesk              : {nicename: 'Upwork'  , urlLocation: 'info.profile_url' }
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
    domains              : domains

    # NOTE: when you add to runtime options above, be sure to modify
    # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`

    # END: PROPERTIES SHARED WITH BROWSER #


  workers = require('./workers')(KONFIG, options, credentials)


  KONFIG.workers = require('underscore').extend workers,
    webserver           :
      instances         : 2
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
      instances         : 4
      supervisord       :
        command         : "node #{projectRoot}/workers/social/index.js -c #{configName} -p #{KONFIG.social.port} -r #{region} --disable-newrelic --kite-port=#{KONFIG.social.kitePort} --kite-key=#{kiteHome}/kite.key"

    # Social API workers
    socialapi           :
      instances         : 2


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
