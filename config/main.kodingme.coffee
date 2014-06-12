fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

rabbitmq        =
  login         : "guest"
  password      : "guest"

hostname        = require("os").hostname()
customDomain    =
  public        : "http://#{hostname}"
  public_       : "#{hostname}"
  local         : "http://127.0.0.1"
  local_        : "localhost"
  port          : 80

version         = "0.0.1"
mongo           = "#{customDomain.local_}:27017/koding"
mongoKontrol    = "#{customDomain.local_}:27017/kontrol"
projectRoot     = nodePath.join __dirname, '..'
socialQueueName = "koding-social-kodingme"
logQueueName    = socialQueueName+'log'




authExchange    = "auth"
authAllExchange = "authAll"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

environment     = "kodingme"

regions         =
  kodingme      : "kodingme"
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
    address     : "#{customDomain.public}:#{customDomain.port}"
  userSitesDomain: "#{customDomain.public}"
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms"
  projectRoot   : projectRoot
  webserver     :
    useCacheHeader: no
    login       : "#{rabbitmq.login}"
    port        : customDomain.port
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  socialApiUrl  : "#{customDomain.public}:7000"
  sourceServer  :
    enabled     : yes
    port        : 3526
  mongo         : mongo
  mongoKontrol  : mongoKontrol
  mongoReplSet  : null
  mongoMinWrites: 1
  neo4j         :
    read        : "#{customDomain.public}"
    write       : "#{customDomain.public}"
    port        : 7474
  runNeo4jFeeder: no
  runGoBroker   : yes
  runGoBrokerKite: yes
  runPremiumBroker: yes
  runPremiumBrokerKite: yes
  runKontrol    : yes
  runRerouting  : yes
  runUserPresence: no
  runPersistence: no
  compileGo     : yes
  buildClient   : yes
  runOsKite     : no
  runTerminalKite: no
  runProxy      : yes
  redis         : "#{customDomain.local}:6379"
  subscriptionEndpoint   : "#{customDomain.public}:#{customDomain.port}/-/subscription/check/"
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    login       : "#{rabbitmq.login}"
    queueName   : socialQueueName+'auth'
    authExchange: authExchange
    authAllExchange: authAllExchange
    numberOfWorkers: 1
    watch       : yes
  emailConfirmationCheckerWorker :
    enabled              : no
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : yes
    cronSchedule         : '0 * * * * *'
    usageLimitInMinutes  : 60
  elasticSearch          :
    host                 : "#{customDomain.local}"
    port                 : 9200
    enabled              : no
    queue                : "elasticSearchFeederQueue"
  guestCleanerWorker     :
    enabled              : yes
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
  sitemapWorker          :
    enabled              : yes
    login                : "#{rabbitmq.login}"
    queueName            : socialQueueName+'sitemapworker'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 00 00 * * *'
  topicModifier          :
    cronSchedule         : '0 */5 * * * *'
  social        :
    login       : "#{rabbitmq.login}"
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
    verbose     : no
    kitePort    : 8765
  log           :
    login       : "#{rabbitmq.login}"
    numberOfWorkers: 1
    watch       : yes
    queueName   : logQueueName
    verbose     : no
    run         : no
    runWorker   : no
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
  client        :
    version     : version
    watch       : yes
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
      useNeo4j: yes
      logToExternal: no  # rollbar, mixpanel etc.
      logToInternal: no  # log worker
      resourceName: socialQueueName
      logResourceName: logQueueName
      socialApiUri: "#{customDomain.public}:3030/xhr"
      logApiUri: "#{customDomain.public}:4030/xhr"
      suppressLogs: no
      broker    :
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/broker"
      premiumBroker:
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/premiumBroker"
      brokerKite:
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/brokerKite"
        brokerExchange: 'brokerKite'
      premiumBrokerKite:
        servicesEndpoint: "#{customDomain.public}:#{customDomain.port}/-/services/premiumBrokerKite"
        brokerExchange: 'premiumBrokerKite'
      apiUri    : "#{customDomain.public}"
      version   : version
      mainUri   : "#{customDomain.public}"
      appsUri   : "https://rest.kd.io"
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
      sourceUri : "#{customDomain.public}:3526"
      newkontrol:
        url     : "ws://#{customDomain.public_}:4000/kontrol"
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
    failoverUri       : customDomain.public_
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
    failoverUri       : customDomain.public_
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
    failoverUri       : customDomain.public_
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
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
