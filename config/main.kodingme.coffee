fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'
hat             = require 'hat'
{argv}          = require 'optimist'
path            = require 'path'

BLD = path.join __dirname,"../install/BUILD_DATA"

hostname        = (fs.readFileSync BLD+"/BUILD_HOSTNAME",   'utf8').replace("\n","")
region          = (fs.readFileSync BLD+"/BUILD_REGION",      'utf8').replace("\n","")
configName      = (fs.readFileSync BLD+"/BUILD_CONFIG",      'utf8').replace("\n","")
environment     = (fs.readFileSync BLD+"/BUILD_ENVIRONMENT", 'utf8').replace("\n","")
projectRoot     = (fs.readFileSync BLD+"/BUILD_PROJECT_ROOT",'utf8').replace("\n","")


rabbitmq        =
  login         : "guest"
  password      : "guest"


customDomain    =
  public        : "http://#{hostname}"
  public_       : "#{hostname}"
  local         : "http://127.0.0.1"
  local_        : "localhost"
  port          : 80

version         = "0.0.1"
mongo           = "#{customDomain.local_}:27017/koding"
mongoKontrol    = "#{customDomain.local_}:27017/kontrol"




socialQueueName = "koding-social-#{configName}"
logQueueName    = socialQueueName+'log'

brokerUniqueId  = hat()

# KEYS
publicKeyFile   = "#{projectRoot}/certs/test_kontrol_rsa_public.pem"
privateKeyFile  = "#{projectRoot}/certs/test_kontrol_rsa_private.pem" 


authExchange    = "auth"
authAllExchange = "authAll"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

regions         =
  kodingme      : "#{configName}"
  vagrant       : "vagrant"
  sj            : "sj"
  aws           : "aws"
  premium       : "vagrant"

cookieMaxAge = 1000 * 60 * 60 * 24 * 14 # two weeks
cookieSecure = no

module.exports = __ =
  environment   : environment
  regions       : regions
  region        : region
  hostname      : hostname
  version       : version
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "#{customDomain.public}:#{customDomain.port}"
  userSitesDomain: "#{customDomain.public}"
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms"
  projectRoot   : projectRoot
  socialapi:
    port        : 7000
    clusterSize : 5
    proxyUrl    : "#{customDomain.local}:7000"
  mongo         : mongo
  mongoKontrol  : mongoKontrol
  mongoReplSet  : null
  mongoMinWrites: 1
  buildClient   : yes
  redis         : "#{customDomain.local}:6379"
  subscriptionEndpoint   : "#{customDomain.public}:#{customDomain.port}/-/subscription/check/"
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes

  kontrolProxy:
    process:
      run : no 
      cmd: "./go/bin/kontrolproxy -c #{configName} -r #{configName} -v"
      restart : no

  kontrolDaemon:
    process:
      run : yes
      cmd: "./go/bin/kontroldaemon -c #{configName}"
      restart : no

  kontrolApi:
    process:
      run : yes
      cmd: "./go/bin/kontrolapi -c #{configName}"
      restart : no

  kontrol:
    process:
      run : yes
      cmd: "./go/bin/kontrol -c #{configName} -r #{configName}"
      restart : no

  proxyKite:
    process:
      run : yes
      cmd: "./go/bin/reverseproxy -region #{configName} -host #{hostname} -env production"
      restart : no

  rerouting :
    process :
      run            : yes
      cmd            : "./go/bin/rerouting -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"
      restart : no

  userpresence:
    process:
      run : no
      cmd            : "./go/bin/userpresence -c #{configName}"
      restart        : yes
      kontrol        :
        enabled      : yes
        startMode    : "one"
      restart : no

  webserver     :
    useCacheHeader: no
    login       : "#{rabbitmq.login}"
    queueName   : socialQueueName+'web'
    watch       : yes
    process     :
      cmd         : "node ./server/index -c #{configName} -p #{customDomain.port} --disable-newrelic" 
      run         : yes

  sourceMapServer :
    watch       : yes
    process     :
      cmd         : "node ./server/lib/source-server -c #{configName} -p 3526"
      run         : yes


  authWorker    :
    login       : "#{rabbitmq.login}"
    queueName   : socialQueueName+'auth'
    authExchange: authExchange
    authAllExchange: authAllExchange
    numberOfWorkers: 1
    watch       : ['./workers/auth']
    process     :
      run        : yes
      cmd   		 : "node ./workers/auth/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "many"

  social        :
    login       : "#{rabbitmq.login}"
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
    verbose     : no
    kitePort    : 8765
    process     :
      run    : yes
      cmd            : "node ./workers/social/index -c #{configName} -p 3030 --disable-newrelic --kite-port=13020"
      kontrol        :
        enabled         : yes
        startMode       : "many"
        registerToProxy : yes
        proxyName       : 'social'
        port            : 8765

  log           :
    login       : "#{rabbitmq.login}"
    numberOfWorkers: 1
    watch       : ['./workers/log']
    queueName   : logQueueName
    process :
      cmd            : "node ./workers/log/index -c #{configName} -p 4029"
      run            : no
      kontrol        :
        enabled      : yes
        startMode    : "many"
        registerToProxy: yes
        proxyName    : 'log'
        port         : 4029
        
  emailConfirmationCheckerWorker :
    enabled              : no
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : ['./workers/emailconfirmationchecker']
    cronSchedule         : '0 * * * * *'
    usageLimitInMinutes  : 60
    process :
      cmd            : "node ./workers/emailconfirmationchecker/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"
  kloudKite :
    process:
      run : yes
      cmd : "go run ./go/src/koding/kites/kloud/main.go -c #{configName} -r #{configName} -public-key #{publicKeyFile} -private-key #{privateKeyFile} -kontrol-url \"ws://#{customDomain.public_}:4000\""

  elasticSearch          :
    host                 : "#{customDomain.local}"
    port                 : 9200
    enabled              : no
    queue                : "elasticSearchFeederQueue"
    process:
      run     : no
      cmd     : "./go/bin/elasticsearchfeeder -c #{configName}"
      restart : yes    
      kontrol        :
        enabled      : yes
        startMode    : "one"

  guestCleanerWorker     :
    enabled              : yes
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 2
    watch                : ['./workers/guestcleaner']
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
    process:
      run            : yes 
      cmd            : "node ./workers/guestcleaner/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"

  cronJobs:
    process :
      run : yes
      cmd : "./go/bin/cron -c #{configName}"

  graphiteFeeder:
    process:
      run : no
      cmd : "./go/bin/graphitefeeder -c #{configName}"

  migratePosts:
    process:
      run : no
      cmd : "./go/bin/posts -c #{configName}"


  sitemapWorker          :
    enabled              : yes
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'sitemapworker'
    numberOfWorkers      : 2
    watch                : ['./workers/sitemapgenerator']
    cronSchedule         : '00 00 00 * * *'
    process :
      run            : no
      cmd            : "node ./workers/sitemapgenerator/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"

  topicModifier          :
    cronSchedule         : '0 */5 * * * *'
  followFeed    :
    host        : "#{customDomain.local}"
    port        : 5672
    componentUser: "#{rabbitmq.login}"
    password    : "#{rabbitmq.login}"
    vhost       : 'followfeed'
  graphFeederWorker:
    numberOfWorkers: 2
  presence      :
    exchange    : 'services-presence'


  mq            :
    host        : "#{customDomain.local_}"
    port        : 5672
    apiAddress  : "#{customDomain.local_}"
    apiPort     : 15672
    login       : "#{rabbitmq.login}"
    componentUser: "#{rabbitmq.login}"
    password    : "#{rabbitmq.password}"
    # heartbeat disabled in vagrant, because it'll interfere with node-inspector
    # when the debugger is paused, the target is not able to send the heartbeat,
    # so it'll disconnect from RabbitMQ if heartbeat is enabled.
    heartbeat   : 0
    vhost       : '/'
  broker              :
    name              : "broker"
    serviceGenericName: "broker"
    ip                : ""
    port              : 8008
    certFile          : ""
    keyFile           : ""
    webProtocol       : 'http:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : customDomain.public_
    process:
      run : yes
      cmd               : "./go/bin/broker -c #{configName} -u #{brokerUniqueId}"
      kontrol           :
        enabled         : yes
        binary          : brokerUniqueId
        port            : 8008
        hostname        : hostname

  email         :
    host        : "#{customDomain.public}"
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker     :
    cronInstant   : '*/10 * * * * *'
    cronDaily     : '0 10 0 * * *'
    run           : no
    forcedRecipient : undefined
    maxAge        : 3
    watch         : ['./workers/emailnotifications']
    process:
      run            : no
      cmd            : "node ./workers/emailnotifications/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"

  emailSender     :
    watch   : ['./workers/emailsender']
    process :
      run            : yes
      cmd            : "node ./workers/emailsender/index -c #{configName}"
      kontrol        :
        enabled      : yes
        startMode    : "one"

  guests          :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize      : 1e4
    batchSize     : undefined
    cleanupCron   : '*/10 * * * * *'
  pidFile         : '/tmp/koding.server.pid'
  newkites        :
    useTLS        : no
    certFile      : ""
    keyFile       : ""
  newkontrol      :
    port            : 4000
    useTLS          : no
    certFile        : ""
    keyFile         : ""
    publicKeyFile   : "./certs/test_kontrol_rsa_public.pem"
    privateKeyFile  : "./certs/test_kontrol_rsa_private.pem"
  proxyKite       :
    domain        : "127.0.0.1"
    certFile      : "./certs/vagrant_127.0.0.1_cert.pem"
    keyFile       : "./certs/vagrant_127.0.0.1_key.pem"
  etcd            : [ {host: "127.0.0.1", port: 4001} ]
  kontrold        :
    vhost         : "/"
    overview      :
      apiHost     : "127.0.0.1"
      apiPort     : 8888
      port        : 8080
      kodingHost  : customDomain.public_
      socialHost  : customDomain.public_
    api           :
      port        : 8888
      url         : "#{customDomain.public}"
    proxy         :
      port        : 80
      portssl     : 443
      ftpip       : '127.0.0.1'

  client        :
    version     : version
    watch       : no
    watchDuration : 300
    includesPath: 'client'
    indexMaster : "index-master.html"
    index       : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"
    runtimeOptions:
      kites: require './kites.coffee'
      osKitePollingMs: 1000 * 60 # 1 min
      userIdleMs: 1000 * 60 * 5  # 5 min
      sessionCookie :
        maxAge      : cookieMaxAge
        secure      : cookieSecure
      environment        : environment
      activityFetchCount : 20
      authExchange       : authExchange
      github         :
        clientId     : "f8e440b796d953ea01e5"
      embedly        :
        apiKey       : embedlyApiKey
      userSitesDomain: "#{customDomain.public}"
      logToExternal: no  # rollbar, mixpanel etc.
      logToInternal: no  # log worker
      resourceName: socialQueueName
      logResourceName: logQueueName
      socialApiUri: "#{customDomain.public}:3030/xhr"
      logApiUri: "#{customDomain.public}:4030/xhr"
      suppressLogs: no
      broker    :
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/broker"
      brokerKite    :
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/brokerKite"
      apiUri    : "#{customDomain.public}"
      version   : version
      mainUri   : "#{customDomain.public}"
      appsUri   : "https://rest.kd.io"
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
      sourceUri : "#{customDomain.public}:3526"
      newkontrol:
        url     : "http://#{customDomain.public_}:4000/kontrol"
      fileFetchTimeout: 15 * 1000 # seconds
      externalProfiles  :
        github          :
          nicename      : 'GitHub'
          urlLocation   : 'html_url'
        odesk           :
          nicename      : 'oDesk'
          urlLocation   : 'info.profile_url'
        facebook        :
          nicename      : 'Facebook'
          urlLocation   : 'link'
        google          :
          nicename      : 'Google'
        linkedin        :
          nicename      : 'LinkedIn'
        twitter         :
          nicename      : 'Twitter'
        # bitbucket     :
        #   nicename    : 'BitBucket'
      troubleshoot      :
        idleTime        : 1000 * 60 * 60
        externalUrl     : "https://s3.amazonaws.com/koding-ping/healthcheck.json"

  recurly         :
    apiKey        : '4a0b7965feb841238eadf94a46ef72ee' # koding-test.recurly.com
    loggedRequests: /^(subscriptions|transactions)/
  embedly       :
    apiKey      : embedlyApiKey
  opsview       :
    push        : no
    host        : ''
    bin         : null
    conf        : null
  github        :
    clientId    : "f8e440b796d953ea01e5"
    clientSecret : "b72e2576926a5d67119d5b440107639c6499ed42"
  odesk          :
    key          : "639ec9419bc6500a64a2d5c3c29c2cf8"
    secret       : "549b7635e1e4385e"
    request_url  : "https://www.odesk.com/api/auth/v1/oauth/token/request"
    access_url   : "https://www.odesk.com/api/auth/v1/oauth/token/access"
    secret_url   : "https://www.odesk.com/services/api/auth?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
    redirect_uri : "#{customDomain}:#{customDomain.port}/-/oauth/odesk/callback"
  facebook       :
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirectUri  : "#{customDomain}:#{customDomain.port}/-/oauth/facebook/callback"
  google         :
    client_id    : "1058622748167.apps.googleusercontent.com"
    client_secret: "vlF2m9wue6JEvsrcAaQ-y9wq"
    redirect_uri : "#{customDomain}:#{customDomain.port}/-/oauth/google/callback"
  statsd         :
    use          : false
    ip           : "#{customDomain}"
    port         : 8125
  graphite       :
    use          : false
    host         : "#{customDomain}"
    port         : 2003
  linkedin       :
    client_id    : "f4xbuwft59ui"
    client_secret: "fBWSPkARTnxdfomg"
    redirect_uri : "#{customDomain}:#{customDomain.port}/-/oauth/linkedin/callback"
  twitter        :
    key          : "aFVoHwffzThRszhMo2IQQ"
    secret       : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E"
    redirect_uri : "#{customDomain}:#{customDomain.port}/-/oauth/twitter/callback"
    request_url  : "https://twitter.com/oauth/request_token"
    access_url   : "https://twitter.com/oauth/access_token"
    secret_url   : "https://twitter.com/oauth/authenticate?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
  mixpanel       : "a57181e216d9f713e19d5ce6d6fb6cb3"
  rollbar        : "71c25e4dc728431b88f82bd3e7a600c9"
  slack          :
    token        : "xoxp-2155583316-2155760004-2158149487-a72cf4"
    channel      : "C024LG80K"
  logLevel        :
    neo4jfeeder   : "notice"
    oskite        : "info"
    terminal      : "info"
    kontrolproxy  : "notice"
    kontroldaemon : "notice"
    userpresence  : "notice"
    vmproxy       : "notice"
    graphitefeeder: "notice"
    sync          : "notice"
    topicModifier : "notice"
    postModifier  : "notice"
    router        : "notice"
    rerouting     : "notice"
    overview      : "notice"
    amqputil      : "notice"
    rabbitMQ      : "notice"
    ldapserver    : "notice"
    broker        : "notice"
  sessionCookie   :
    maxAge        : cookieMaxAge
    secure        : cookieSecure
  troubleshoot    :
    recipientEmail: "can@koding.com"



