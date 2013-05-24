fs = require 'fs'
nodePath = require 'path'
deepFreeze = require 'koding-deep-freeze'

version = "0.0.1"
projectRoot = nodePath.join __dirname, '..'

rabbitPrefix = (
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e
    console.log "You're missing .rabbitvhost file. Please add it with your name in it."
    throw e
).trim()
socialQueueName = "koding-social-klusterdev-#{rabbitPrefix}"

module.exports =
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : 'RkZRBOR8jtbAo+to2nbYWwPlZvzG9ZjyC8yhTh1q'
  uri           :
    address     : "http://localhost:3000"
  userSitesDomain: 'kd.io'
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'webserver'
    port        : 3000
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  sourceServer  :
    enabled     : yes
    port        : 1337
  neo4j         :
    read        : "http://neo4j-dev.in.koding.com"
    write       : "http://neo4j-dev.in.koding.com"
    port        : 7474
  mongo         : 'dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy'
  runNeo4jFeeder: no
  runGoBroker   : no
  runKontrol    : no
  runRerouting  : no
  compileGo     : no
  buildClient   : yes
  runOsKite     : no
  runProxy      : no
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
  loggr:
    push   : no
    url    : ""
    apiKey : ""
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
    login       : 'prod-auth-worker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 1
    watch       : yes
  social        :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
  cacheWorker   :
    login       : 'prod-social'
    watch       : yes
    queueName   : socialQueueName+'cache'
    run         : no
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2
  presence      :
    exchange    : 'services-presence'
  client        :
    version     : version
    watch       : yes
    watchDuration: 250
    includesPath: 'client'
    websitePath : 'website'
    js          : "js/kd.#{version}.js"
    css         : "css/kd.#{version}.css"
    indexMaster : "index-master.html"
    index       : "index.html"
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3000'
    runtimeOptions:
      userSitesDomain: 'kd.io'
      useNeo4j: no
      logToExternal: no  # rollbar, mixpanel etc.
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        sockJS  : 'http://kluster-dev.in.koding.com:8008/subscribe'
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
      sourceUri : 'http://localhost:1337'
  mq            :
    host        : 'kluster-dev.in.koding.com'
    port        : 5672
    apiAddress  : "kluster-dev.in.koding.com"
    apiPort     : 15672
    login       : 'PROD-k5it50s4676pO9O'
    componentUser: "PROD-k5it50s4676pO9O"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 10
    vhost       : '/'
  broker        :
    ip          : ""
    port        : 8008
    certFile    : ""
    keyFile     : ""
    ip          : ""
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
    defaultRecepient : undefined
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
      sslips      : '127.0.0.1'
    mongo         :
      host        : 'kontrol.in.koding.com'
    rabbitmq      :
      host        : 'kontrol.in.koding.com'
      port        : '5672'
      login       : 'guest'
      password    : 's486auEkPzvUjYfeFTMQ'
      vhost       : '/'
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a'
