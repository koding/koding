zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'

Configuration = (options={}) ->

  prod_simulation_server = "10.0.0.248"

  publicPort     = options.publicPort          = "80"
  hostname       = options.hostname            = "sandbox.koding.com#{if publicPort is "80" then "" else ":"+publicPort}"
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
  rabbitmq            = { host:     "#{prod_simulation_server}"              , port:               5672                                  , apiPort:         15672                  , login:           "guest"                              , password: "guest"                , vhost:         "/"                                                 }
  mq                  = { host:     "#{rabbitmq.host}"                       , port:               rabbitmq.port                         , apiAddress:      "#{rabbitmq.host}"     , apiPort:         "#{rabbitmq.apiPort}"                , login:    "#{rabbitmq.login}"    , componentUser: "#{rabbitmq.login}"                                   , password:       "#{rabbitmq.password}"                                , heartbeat:       0           , vhost:        "#{rabbitmq.vhost}" }
  customDomain        = { public:   "https://#{hostname}"                    , public_:            "#{hostname}"                         , local:           "http://localhost"     , local_:          "localhost"                          , port:     80                   }
  sendgrid            = { username: "koding"                                 , password:           "DEQl7_Dr"                          }
  email               = { host:     "#{customDomain.public_}"                , protocol:           'https:'                              , defaultFromMail: 'hello@koding.com'     , defaultFromName: 'koding'                             , username: sendgrid.username      , password:      sendgrid.password }
  kontrol             = { url:      "#{options.publicHostname}/kontrol/kite" , port:               4000                                  , useTLS:          no                     , certFile:        ""                                   , keyFile:  ""                     , publicKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_public.pem"    , privateKeyFile: "#{projectRoot}/certs/test_kontrol_rsa_private.pem" }
  broker              = { name:     "broker"                                 , serviceGenericName: "broker"                              , ip:              ""                     , webProtocol:     "https:"                             , host:     customDomain.public    , port:          8008                                                  , certFile:       ""                                                    , keyFile:         ""          , authExchange: "auth"                , authAllExchange: "authAll" , failoverUri: customDomain.public }
  regions             = { kodingme: "#{configName}"                          , vagrant:            "vagrant"                             , sj:              "sj"                   , aws:             "aws"                                , premium:  "vagrant"            }
  algolia             = { appId:    'DYVV81J2S1'                             , apiKey:             '303eb858050b1067bcd704d6cbfb977c'    , indexSuffix:     '.sandbox'           }
  algoliaSecret       = { appId:    algolia.appId                            , apiKey:             algolia.apiKey                        , indexSuffix:     algolia.indexSuffix    , apiSecretKey:    '041427512bcdcd0c7bd4899ec8175f46' }
  mixpanel            = { token:    "a57181e216d9f713e19d5ce6d6fb6cb3"       , enabled:            no                                  }
  postgres            = { host:     "#{prod_simulation_server}"              , port:               5432                                  , username:        "socialapplication"    , password:        "socialapplication"                  , dbname:   "social"             }
  kiteHome            = "#{projectRoot}/kite_home/koding"
  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go
  socialapiProxy      =
    hostname          : "localhost"
    port              : "7000"

  socialapi =
    proxyUrl          : "http://#{socialapiProxy.hostname}:#{socialapiProxy.port}"
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

  userSitesDomain     = "svm.koding.io"
  socialQueueName     = "koding-social-#{configName}"
  logQueueName        = socialQueueName+'log'

  KONFIG              =
    environment                    : environment
    regions                        : regions
    region                         : region
    hostname                       : hostname
    publicPort                     : publicPort
    publicHostname                 : publicHostname
    version                        : version
    broker                         : broker
    uri                            : address: customDomain.public
    userSitesDomain                : userSitesDomain
    projectRoot                    : projectRoot
    socialapi                      : socialapi
    mongo                          : mongo
    kiteHome                       : kiteHome
    redis                          : "#{redis.host}:#{redis.port}"
    misc                           : {claimGlobalNamesForUsers: no , updateAllSlugs : no , debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #

    webserver                      : {port          : 3000                        , useCacheHeader: no                      , kitePort          : 8860 }
    authWorker                     : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth'      , authExchange      : "auth"                                  , authAllExchange : "authAll"}
    mq                             : mq
    emailWorker                    : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'              , run               : yes                                     , forcedRecipient : email.forcedRecipient               , maxAge: 3 }
    elasticSearch                  : {host          : "#{prod_simulation_server}" , port      : 9200                        , enabled           : no                                      , queue           : "elasticSearchFeederQueue"}
    social                         : {port          : 3030                        , login     : "#{rabbitmq.login}"         , queueName         : socialQueueName                         , kitePort        : 8760 }
    email                          : email
    newkites                       : {useTLS        : no                          , certFile  : ""                          , keyFile: "#{kiteHome}/kite.key"  }
    log                            : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}
    boxproxy                       : {port          : 80 }
    sourcemaps                     : {port          : 3526 }
    appsproxy                      : {port          : 3500 }

    kloud                          : {port          : 5500                        , privateKeyFile : kontrol.privateKeyFile , publicKeyFile: kontrol.publicKeyFile                        , kontrolUrl: kontrol.url                               , registerUrl : "#{customDomain.public}/kloud/kite" }

    emailConfirmationCheckerWorker : {enabled: no                                 , login : "#{rabbitmq.login}"             , queueName: socialQueueName+'emailConfirmationCheckerWorker' , cronSchedule: '0 * * * * *'                           , usageLimitInMinutes  : 60}

    kontrol                        : kontrol
    newkontrol                     : kontrol

    # -- MISC SERVICES --#
    recurly                        : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'             , loggedRequests: "/^(subscriptions|transactions)/"}
    sendgrid                       : sendgrid
    opsview                        : {push          : no                                             , host          : ''                                           , bin: null                                                                             , conf: null}
    github                         : {clientId      : "d3b586defd01c24bb294"                         , clientSecret  : "8eb80af7589972328022e80c02a53f3e2e39a323"}
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
    recapthcha                     : '6LfZL_kSAAAAAIrbAbnMPt9ri79pyHUZ0-QqB6Iz'
    segment                        : '4c570qjqo0'

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client                         : {watch: yes , version: version , includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  KONFIG.client.runtimeOptions =
    kites             : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia           : algolia
    logToExternal     : no                                 # rollbar , mixpanel etc.
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
    broker            : {uri          : "/subscribe" }
    appsUri           : "/appsproxy"
    uploadsUri        : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout  : 1000 * 15
    userIdleMs        : 1000 * 60 * 5
    embedly           : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    github            : {clientId     : "d3b586defd01c24bb294" }
    newkontrol        : {url          : "#{kontrol.url}"}
    sessionCookie     : {maxAge       : 1000 * 60 * 60 * 24 * 14  , secure: no   }
    troubleshoot      : {idleTime     : 1000 * 60 * 60            , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    recaptcha         : '6LfZL_kSAAAAABDrxNU5ZAQk52jx-2sJENXRFkTO'
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
    kontrol             :
      group             : "environment"
      ports             :
        incoming        : "#{kontrol.port}"
      supervisord       :
        command         : "#{GOBIN}/kontrol -region #{region} -machines #{etcd} -environment #{environment} -mongourl #{KONFIG.mongo} -port #{kontrol.port} -privatekey #{kontrol.privateKeyFile} -publickey #{kontrol.publicKeyFile}"
      nginx             :
        websocket       : yes
        locations       : ["~^/kontrol/.*"]

    kloud               :
      group             : "environment"
      ports             :
        incoming        : "#{KONFIG.kloud.port}"
      supervisord       :
        command         : "#{GOBIN}/kloud -hostedzone #{userSitesDomain} -region #{region} -environment #{environment} -port #{KONFIG.kloud.port} -publickey #{kontrol.publicKeyFile} -privatekey #{kontrol.privateKeyFile} -kontrolurl #{kontrol.url}  -registerurl #{KONFIG.kloud.registerUrl} -mongourl #{KONFIG.mongo} -prodmode=#{configName is "prod"}"
      nginx             :
        websocket       : yes
        locations       : ["~^/kloud/.*"]

    # ngrokProxy          :
    #   group             : "environment"
    #   supervisord       :
    #     command         : "coffee #{projectRoot}/ngrokProxy --user #{publicHostname}"

    # reverseProxy        :
    #   group             : "environment"
    #   supervisord       :
    #     command         : "#{GOBIN}/reverseproxy -port 1234 -env production -region #{publicHostname}PublicEnvironment -publicHost proxy-#{publicHostname}.ngrok.com -publicPort 80"

    broker              :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.broker.port}"
      supervisord       :
        command         : "#{GOBIN}/broker -c #{configName}"
      nginx             :
        websocket       : yes
        locations       : ["/websocket", "~^/subscribe/.*"]

    rerouting           :
      group             : "webserver"
      supervisord       :
        command         : "#{GOBIN}/rerouting -c #{configName}"

    authworker          :
      group             : "webserver"
      instances         : 2
      supervisord       :
        command         : "node #{projectRoot}/workers/auth/index.js -c #{configName} --disable-newrelic"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      supervisord       :
        command         : "node #{projectRoot}/servers/sourcemaps/index.js -c #{configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"

    emailsender         :
      group             : "webserver"
      supervisord       :
        command         : "node #{projectRoot}/workers/emailsender/index.js  -c #{configName} --disable-newrelic"

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
        locations       : ["/"]
        auth            : yes

    socialworker        :
      group             : "webserver"
      instances         : 2
      ports             :
        incoming        : "#{KONFIG.social.port}"
        outgoing        : "#{KONFIG.social.kitePort}"
      supervisord       :
        command         : "node #{projectRoot}/workers/social/index.js -c #{configName} -p #{KONFIG.social.port} -r #{region} --disable-newrelic --kite-port=#{KONFIG.social.kitePort} --kite-key=#{kiteHome}/kite.key"
      nginx             :
        locations       : ["/xhr"]

    guestCleaner        :
      group             : "webserver"
      supervisord       :
        command         : "#{GOBIN}/guestcleanerworker -c #{configName}"

    # clientWatcher       :
    #   group             : "webserver"
    #   supervisord       :
    #     command         : "ulimit -n 1024 && coffee #{projectRoot}/build-client.coffee  --watch --sourceMapsUri /sourcemaps --verbose true"



    # Social API workers
    socialapi           :
      group             : "socialapi"
      instances         : 2
      ports             :
        incoming        : "#{socialapiProxy.port}"
      supervisord       :
        command         : "#{GOBIN}/api  -c #{socialapi.configFilePath} -port=#{socialapiProxy.port}"

    dailyemailnotifier  :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/dailyemailnotifier -c #{socialapi.configFilePath}"

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

    emailnotifier       :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/emailnotifier -c #{socialapi.configFilePath}"

    topicfeed           :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/topicfeed -c #{socialapi.configFilePath}"

    trollmode           :
      group             : "socialapi"
      supervisord       :
        command         : "#{GOBIN}/trollmode -c #{socialapi.configFilePath}"


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
      export HOME=/root
      export KONFIG_JSON='#{KONFIG.JSON}'
      coffee ./build-client.coffee --watch false
      """

  KONFIG.ENV             = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.nginxConf       = (require "../deployment/nginx.coffee").create KONFIG.workers, environment
  KONFIG.runFile         = generateRunFile KONFIG
  KONFIG.supervisorConf  = (require "../deployment/supervisord.coffee").create KONFIG

  return KONFIG

module.exports = Configuration
