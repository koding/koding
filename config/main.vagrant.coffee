fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

version         = "0.0.1"
mongo           = 'localhost:27017/koding'
mongoKontrol    = 'localhost:27017/kontrol'
projectRoot     = nodePath.join __dirname, '..'
socialQueueName = "koding-social-vagrant"
logQueueName    = socialQueueName+'log'

authExchange    = "auth"
authAllExchange = "authAll"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

environment     = "vagrant"
regions         =
  vagrant       : "vagrant"
  sj            : "sj"
  aws           : "aws"
  premium       : "vagrant"

cookieMaxAge = 1000 * 60 * 60 * 24 * 14 # two weeks
cookieSecure = no

module.exports =
  environment   : environment
  regions       : regions
  version       : version
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://lvh.me:3020"
  userSitesDomain: 'lvh.me'
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms"
  projectRoot   : projectRoot
  webserver     :
    useCacheHeader: no
    login       : 'prod-webserver'
    port        : 3020
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  socialapi:
    port        : 7000
    clusterSize : 5
    proxyUrl    : "http://localhost:7000"
  sourceServer  :
    enabled     : yes
    port        : 3526
  mongo         : mongo
  mongoKontrol  : mongoKontrol
  mongoReplSet  : null
  mongoMinWrites: 1
  runGoBroker   : yes
  runGoBrokerKite: yes
  runPremiumBroker: yes
  runPremiumBrokerKite: yes
  runKontrol    : yes
  runRerouting  : yes
  compileGo     : yes
  buildClient   : yes
  runOsKite     : yes
  runTerminalKite: yes
  runProxy      : yes
  redis         : "localhost:6379"
  subscriptionEndpoint   : "http://192.168.42.1:3020/-/subscription/check/"
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    login       : 'prod-auth-worker'
    queueName   : socialQueueName+'auth'
    authExchange: authExchange
    authAllExchange: authAllExchange
    numberOfWorkers: 1
    watch       : yes
  emailConfirmationCheckerWorker :
    enabled              : no
    login                : 'prod-social'
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : yes
    cronSchedule         : '0 * * * * *'
    usageLimitInMinutes  : 60
  elasticSearch          :
    host                 : "localhost"
    port                 : 9200
    enabled              : no
    queue                : "elasticSearchFeederQueue"
  guestCleanerWorker     :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
  sitemapWorker          :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'sitemapworker'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 00 00 * * *'
  social        :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
    verbose     : no
    kitePort    : 8765
  log           :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : yes
    queueName   : logQueueName
    verbose     : no
    run         : no
    runWorker   : yes
  followFeed    :
    host        : 'localhost'
    port        : 5672
    componentUser: 'guest'
    password    : 'guest'
    vhost       : 'followfeed'
  presence      :
    exchange    : 'services-presence'
  client        :
    version     : version
    watch       : yes
    watchDuration : 300
    includesPath: 'client'
    indexMaster : "index-master.html"
    index       : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://lvh.me:3020'
    runtimeOptions:
      kites: require './kites.coffee'
      algolia:
        appId: '8KD9RHY1OA'
        apiKey: 'e4a8ebe91bf848b67c9ac31a6178c64b'
        indexSuffix: '.vagrant'
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
      userSitesDomain: 'lvh.me'
      logToExternal: no  # rollbar, mixpanel etc.
      logToInternal: no  # log worker
      resourceName: socialQueueName
      logResourceName: logQueueName
      socialApiUri: 'http://lvh.me:3030/xhr'
      logApiUri: 'http://lvh.me:4030/xhr'
      suppressLogs: no
      broker    :
        servicesEndpoint: 'http://lvh.me:3020/-/services/broker'
      premiumBroker:
        servicesEndpoint: 'http://lvh.me:3020/-/services/premiumBroker'
      brokerKite:
        servicesEndpoint: 'http://lvh.me:3020/-/services/brokerKite'
        brokerExchange: 'brokerKite'
      premiumBrokerKite:
        servicesEndpoint: 'http://lvh.me:3020/-/services/premiumBrokerKite'
        brokerExchange: 'premiumBrokerKite'
      apiUri    : 'http://lvh.me:3020'
      version   : version
      mainUri   : 'http://lvh.me:3020'
      appsUri   : 'https://rest.kd.io'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
      sourceUri : 'http://lvh.me:3526'
      newkontrol:
        url     : 'http://127.0.0.1:4000/kite'
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
      recaptcha         : "6LdLAPcSAAAAAG27qiKqlnowAM8FXfKSpW1wx_bU"
  mq            :
    host        : 'localhost'
    port        : 5672
    apiAddress  : "localhost"
    apiPort     : 15672
    login       : 'PROD-k5it50s4676pO9O'
    componentUser: "PROD-k5it50s4676pO9O"
    password    : 'djfjfhgh4455__5'
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
    failoverUri       : 'lvh.me'
  premiumBroker       :
    name              : "premiumBroker"
    serviceGenericName: "broker"
    ip                : ""
    port              : 8009
    certFile          : ""
    keyFile           : ""
    webProtocol       : 'http:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'lvh.me'
  brokerKite          :
    name              : "brokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 8010
    certFile          : ""
    keyFile           : ""
    webProtocol       : 'http:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'lvh.me'
  premiumBrokerKite   :
    name              : "premiumBrokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 8011
    certFile          : ""
    keyFile           : ""
    webProtocol       : 'http:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'lvh.me'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'lvh.me:3020'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker     :
    cronInstant   : '*/10 * * * * *'
    cronDaily     : '0 10 0 * * *'
    run           : no
    forcedRecipient : undefined
    maxAge        : 3
  emailSender     :
    run           : no
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
    certFile      : "/opt/koding/certs/vagrant_127.0.0.1_cert.pem"
    keyFile       : "/opt/koding/certs/vagrant_127.0.0.1_key.pem"
  etcd            : [ {host: "127.0.0.1", port: 4001} ]
  kontrold        :
    vhost         : "/"
    overview      :
      apiHost     : "127.0.0.1"
      apiPort     : 8888
      port        : 8080
      kodingHost  : "example.com"
      socialHost  : "social.example.com"
    api           :
      port        : 8888
      url         : "http://lvh.me"
    proxy         :
      port        : 80
      portssl     : 443
      ftpip       : '127.0.0.1'
  # crypto :
  #   encrypt: (str,key=Math.floor(Date.now()/1000/60))->
  #     crypto = require "crypto"
  #     str = str+""
  #     key = key+""
  #     cipher = crypto.createCipher('aes-256-cbc',""+key)
  #     cipher.update(str,'utf-8')
  #     a = cipher.final('hex')
  #     return a
  #   decrypt: (str,key=Math.floor(Date.now()/1000/60))->
  #     crypto = require "crypto"
  #     str = str+""
  #     key = key+""
  #     decipher = crypto.createDecipher('aes-256-cbc',""+key)
  #     decipher.update(str,'hex')
  #     b = decipher.final('utf-8')
  #     return b
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
    redirect_uri : "http://lvh.me:3020/-/oauth/odesk/callback"
  facebook       :
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirectUri  : "http://lvh.me:3020/-/oauth/facebook/callback"
  google         :
    client_id    : "1058622748167.apps.googleusercontent.com"
    client_secret: "vlF2m9wue6JEvsrcAaQ-y9wq"
    redirect_uri : "http://lvh.me:3020/-/oauth/google/callback"
  statsd         :
    use          : false
    ip           : "lvh.me"
    port         : 8125
  graphite       :
    use          : false
    host         : "lvh.me"
    port         : 2003
  linkedin       :
    client_id    : "f4xbuwft59ui"
    client_secret: "fBWSPkARTnxdfomg"
    redirect_uri : "http://lvh.me:3020/-/oauth/linkedin/callback"
  twitter        :
    key          : "aFVoHwffzThRszhMo2IQQ"
    secret       : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E"
    redirect_uri : "http://127.0.0.1:3020/-/oauth/twitter/callback"
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
    oskite        : "info"
    terminal      : "info"
    kontrolproxy  : "notice"
    kontroldaemon : "notice"
    vmproxy       : "notice"
    graphitefeeder: "info"
    sync          : "notice"
    postModifier  : "notice"
    router        : "notice"
    rerouting     : "notice"
    overview      : "notice"
    amqputil      : "notice"
    rabbitMQ      : "notice"
    ldapserver    : "notice"
    broker        : "notice"
  defaultVMConfigs:
    freeVM        :
      storage     : 3072
      ram         : 1024
      cpu         : 1
  sessionCookie   :
    maxAge        : cookieMaxAge
    secure        : cookieSecure
  troubleshoot    :
    recipientEmail: "can@koding.com"
  recaptcha       : "6LdLAPcSAAAAAJe857OKXNdYzN3C1D55DwGW0RgT"
