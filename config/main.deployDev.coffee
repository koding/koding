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

socialQueueName = "koding-social-#{rabbitPrefix}"

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
  mongo         : 'dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy'
  runGoBroker   : no
  runKontrol    : no
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
    login       : 'authWorker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 1
    watch       : yes
  social        :
    login       : 'social'
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
  presence        :
    exchange      : 'services-presence'
  client          :
    version       : version
    watch         : yes
    watchDuration : 300
    includesPath  : 'client'
    websitePath   : 'website'
    js            : "js/kd.#{version}.js"
    css           : "css/kd.#{version}.css"
    indexMaster   : "index-master.html"
    index         : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3000'
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        sockJS  : 'https://dmq.koding.com:8008/subscribe'
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
      sourceUri : 'http://localhost:1337'
  mq            :
    host        : 'web-dev.in.koding.com'
    port        : 5672
    apiAddress  : "web-dev.in.koding.com"
    apiPort     : 15672
    login       : 'guest'
    componentUser: "guest"
    password    : 's486auEkPzvUjYfeFTMQ'
    heartbeat   : 10
    vhost       : '/'
  broker        :
    port        : 8008
    certFile    : ""
    keyFile     : ""
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
    mongo         :
      host        : '127.0.0.1'
    rabbitmq      :
      host        : 'salt-master.in.koding.com'
      port        : '5672'
      login       : 'guest'
      password    : 'HV5l856bME'
      vhost       : '/'
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a'
