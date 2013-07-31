fs = require 'fs'
nodePath = require 'path'
deepFreeze = require 'koding-deep-freeze'

version = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()
projectRoot = nodePath.join __dirname, '..'

socialQueueName = "koding-social-#{version}"

authExchange    = "auth-#{version}"
authAllExchange = "authAll-#{version}"

module.exports =
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "https://koding.com"
  userSitesDomain: 'kd.io'
  containerSubnet: "10.128.2.0/9"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3000
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : no
  sourceServer  :
    enabled     : yes
    port        : 1337
  neo4j         :
    read        : "http://internal-neo4j-read-elb-1962816121.us-east-1.elb.amazonaws.com"
    write       : "http://internal-neo4j-write-elb-1924664554.us-east-1.elb.amazonaws.com"
    port        : 7474
  mongo         : 'dev:k9lc4G1k32nyD72@kmongodb1.in.koding.com:27017/koding'
  runNeo4jFeeder: yes
  runGoBroker   : no
  runKontrol    : yes
  runRerouting  : yes
  runUserPresence: yes
  runPersistence: yes
  compileGo     : no
  buildClient   : yes
  runOsKite     : no
  runProxy      : no
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  uploads       :
    enableStreamingUploads: yes
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccountId        : '616271189586'
      awsAccessKeyId      : 'AKIAJO74E23N33AFRGAQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  loggr:
    push: yes
    url: "http://post.loggr.net/1/logs/koding/events"
    apiKey: "eb65f620b72044118015d33b4177f805"
  librato :
    push      : no
    email     : ""
    token     : ""
    interval  : 60000
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    authExchange: authExchange
    authAllExchange: authAllExchange
    login       : 'prod-authworker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 2
    watch       : no
  graphFeederWorker:
    numberOfWorkers: 2
  social        :
    login       : 'prod-social'
    numberOfWorkers: 7
    watch       : no
    queueName   : socialQueueName
    verbose     : no
  cacheWorker   :
    login       : 'prod-social'
    watch       : no
    queueName   : socialQueueName+'cache'
    run         : no
  presence        :
    exchange      : 'services-presence'
  client          :
    version       : version
    watch         : no
    watchDuration : 300
    includesPath  : 'client'
    websitePath   : 'website'
    js            : "js/kd.#{version}.js"
    css           : "css/kd.#{version}.css"
    indexMaster   : "index-master.html"
    index         : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: "https://koding.com"
    runtimeOptions:
      authExchange: authExchange
      github        :
        clientId    : "5891e574253e65ddb7ea"
      userSitesDomain: 'kd.io'
      useNeo4j: yes
      logToExternal : yes
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : "http://koding.com"
      broker    :
        servicesEndpoint: "/-/services/broker"
        sockJS   : "https://broker-#{version}.koding.com/subscribe"
      apiUri    : 'https://www.koding.com'
      # Is this correct?
      appsUri   : 'https://koding-apps.s3.amazonaws.com'
      sourceUri : "http://webserver-build-koding-#{version}a.in.koding.com:1337"
  mq            :
    host        : 'rabbitmq.in.koding.com'
    port        : 5672
    apiAddress  : "rabbitmq.in.koding.com"
    apiPort     : 15672
    login       : 'guest'
    componentUser: "guest"
    password    : 's486auEkPzvUjYfeFTMQ'
    heartbeat   : 20
    vhost       : 'new'
  broker        :
    ip          : ""
    port        : 443
    certFile    : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile     : "/opt/ssl_certs/wildcard.koding.com.key"
    useKontrold : yes
    webProtocol : 'https:'
    webHostname : "broker-#{version}a.koding.com"
    webPort     : null
    authExchange: authExchange
    authAllExchange: authAllExchange
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : "koding.com"
    protocol    : 'https:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    forcedRecipient : undefined
  emailSender   :
    run         : no
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  pidFile       : '/tmp/koding.server.pid'
  haproxy:
    webPort     : 3020
  kontrold        :
    api           :
      port        : 80
    proxy         :
      port        : 80
      portssl     : 443
      ftpip       : '54.208.3.200'
      sslips      : '10.0.5.231,10.0.5.215,10.0.5.102'
    rabbitmq      :
      host        : 'kontrol.in.koding.com'
      port        : '5672'
      login       : 'guest'
      password    : 's486auEkPzvUjYfeFTMQ'
      vhost       : '/'
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a' # koding.recurly.com
  embedly       :
    apiKey      : 'd03fb0338f2849479002fe747bda2fc7'
  opsview	:
    push	: yes
    host	: 'opsview.in.koding.com'
    bin   : '/usr/local/nagios/bin/send_nsca'
    conf  : '/usr/local/nagios/etc/send_nsca.cfg'
  followFeed    :
    host        : 'rabbitmq1.in.koding.com'
    port        : 5672
    componentUser: 'guest'
    password    : 's486auEkPzvUjYfeFTMQ'
    vhost       : 'followfeed'
  github        :
    clientId    : "5891e574253e65ddb7ea"
    clientSecret: "9c8e89e9ae5818a2896c01601e430808ad31c84a"
