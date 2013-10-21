fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

version         = "0.0.1"
mongo           = 'localhost:27017/koding'
projectRoot     = nodePath.join __dirname, '..'
socialQueueName = "koding-social-vagrant"

authExchange    = "auth"
authAllExchange = "authAll"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

module.exports =
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://localhost:3020"
  userSitesDomain: 'localhost'
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3020
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  sourceServer  :
    enabled     : yes
    port        : 3526
  mongo         : mongo
  mongoReplSet  : null
  neo4j         :
    read        : "http://localhost"
    write       : "http://localhost"
    port        : 7474
  runNeo4jFeeder: yes
  runGoBroker   : yes
  runKontrol    : no
  runRerouting  : yes
  runUserPresence: yes
  runPersistence: no
  compileGo     : yes
  buildClient   : yes
  runOsKite     : yes
  runProxy      : yes
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  uploads       :
    enableStreamingUploads: no
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccountId        : '616271189586'
      awsAccessKeyId      : 'AKIAJO74E23N33AFRGAQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
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
  cacheWorker   :
    login       : 'prod-social'
    watch       : yes
    queueName   : socialQueueName+'cache'
    run         : no
  followFeed    :
    host        : 'localhost'
    port        : 5672
    componentUser: 'guest'
    password    : 'guest'
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
    staticFilesBaseUrl: 'http://localhost:3020'
    runtimeOptions:
      precompiledApi: no
      authExchange: authExchange
      github         :
        clientId     : "f8e440b796d953ea01e5"
      embedly        :
        apiKey       : embedlyApiKey
      userSitesDomain: 'localhost'
      useNeo4j: yes
      logToExternal: no  # rollbar, mixpanel etc.
      resourceName: socialQueueName
      suppressLogs: no
      broker    :
        servicesEndpoint: 'http://localhost:3020/-/services/broker'
        sockJS  : 'http://localhost:8008/subscribe'
      apiUri    : 'http://localhost:3020'
      version   : version
      mainUri   : 'http://localhost:3020'
      appsUri   : 'https://koding-apps.s3.amazonaws.com'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      sourceUri : 'http://localhost:3526'
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
  broker        :
    ip          : ""
    port        : 8008
    certFile    : ""
    keyFile     : ""
    webProtocol : 'http:'
    webHostname : 'localhost'
    webPort     : 8008
    authExchange: authExchange
    authAllExchange: authAllExchange
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    forcedRecipient : undefined
  emailSender     :
    run           : no
  guests          :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize      : 1e4
    batchSize     : undefined
    cleanupCron   : '*/10 * * * * *'
  pidFile         : '/tmp/koding.server.pid'
  loggr           :
    push          : no
    url           : ""
    apiKey        : ""
  librato         :
    push          : no
    email         : ""
    token         : ""
    interval      : 60000
  haproxy         :
    webPort       : 3020
  kontrold        :
    vhost         : "/"
    overview      :
      apiHost     : "127.0.0.1"
      apiPort     : 8888
      port        : 8080
      switchHost  : "example.com"
    api           :
      port        : 8888
    proxy         :
      port        : 80
      portssl     : 8081
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
  recurly       :
    apiKey      : '4a0b7965feb841238eadf94a46ef72ee' # koding-test.recurly.com
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
  facebook       :
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirectUri  : "http://localhost:3020/-/oauth/facebook/callback"
  google         :
    client_id    : "1058622748167.apps.googleusercontent.com"
    client_secret: "vlF2m9wue6JEvsrcAaQ-y9wq"
    redirect_uri : "http://localhost:3020/-/oauth/google/callback"
  statsd         :
    use          : false
    ip           : "localhost"
    port         : 8125
