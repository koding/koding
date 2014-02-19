fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

version         = "0.0.1"
mongo           = 'localhost:27017/koding'
mongoKontrol    = 'localhost:27017/kontrol'
projectRoot     = nodePath.join __dirname, '..'
socialQueueName = "koding-social-vagrant"

authExchange    = "auth"
authAllExchange = "authAll"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

environment     = "vagrant"
regions         =
  vagrant       : "vagrant"
  sj            : "sj"
  aws           : "aws"

module.exports =
  environment   : environment
  regions       : regions
  version       : version
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://localhost:3020"
  userSitesDomain: 'localhost'
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
  sourceServer  :
    enabled     : yes
    port        : 3526
  mongo         : mongo
  mongoKontrol  : mongoKontrol
  mongoReplSet  : null
  neo4j         :
    read        : "http://localhost"
    write       : "http://localhost"
    port        : 7474
  runNeo4jFeeder: yes
  runGoBroker   : yes
  runGoBrokerKite: yes
  runKontrol    : yes
  runRerouting  : yes
  runUserPresence: yes
  runPersistence: no
  compileGo     : yes
  buildClient   : yes
  runOsKite     : yes
  runProxy      : yes
  redis         : "localhost:6379"
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
  topicModifier          :
    cronSchedule         : '0 */5 * * * *'
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
      environment        : environment
      activityFetchCount : 20
      precompiledApi     : no
      authExchange       : authExchange
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
      brokerKite:
        servicesEndpoint: 'http://localhost:3020/-/services/brokerKite'
        brokerExchange: 'brokerKite'
        sockJS  : 'http://localhost:8009/subscribe'
      apiUri    : 'http://localhost:3020'
      version   : version
      mainUri   : 'http://localhost:3020'
      appsUri   : 'https://koding-apps.s3.amazonaws.com'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      sourceUri : 'http://localhost:3526'
      newkontrol:
        url     : 'ws://127.0.0.1:4000/kontrol'
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
    name        : "broker"
    ip          : ""
    port        : 8008
    certFile    : ""
    keyFile     : ""
    webProtocol : 'http:'
    webHostname : 'localhost'
    webPort     : 8008
    authExchange: authExchange
    authAllExchange: authAllExchange
  brokerKite    :
    name        : "brokerKite"
    ip          : ""
    port        : 8009
    certFile    : ""
    keyFile     : ""
    webProtocol : 'http:'
    webHostname : 'localhost'
    webPort     : 8009
    authExchange: authExchange
    authAllExchange: authAllExchange
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'localhost:3020'
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
  newkontrol      :
    username        : "devrim"
    port            : 4000
    useTLS          : no
    certFile        : ""
    keyFile         : ""
    publicKeyFile   : "/opt/koding/certs/test_kontrol_rsa_public.pem"
    privateKeyFile  : "/opt/koding/certs/test_kontrol_rsa_private.pem"
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
      switchHost  : "example.com"
    api           :
      port        : 8888
      url         : "http://localhost"
    proxy         :
      port        : 5000
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
    redirect_uri : "http://localhost:3020/-/oauth/odesk/callback"
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
  graphite       :
    use          : false
    host         : "localhost"
    port         : 2003
  linkedin       :
    client_id    : "f4xbuwft59ui"
    client_secret: "fBWSPkARTnxdfomg"
    redirect_uri : "http://localhost:3020/-/oauth/linkedin/callback"
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
    neo4jfeeder   : "notice"
    oskite        : "notice"
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
      storage     : 4096
      ram         : 1024
      cpu         : 1
