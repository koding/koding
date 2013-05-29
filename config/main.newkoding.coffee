fs = require 'fs'
nodePath = require 'path'

version = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()

# DEV
mongo = 'dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy'

projectRoot = nodePath.join __dirname, '..'

rabbitPrefix = ((
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e then require("os").hostname()
).trim())+"-dev-#{version}"
rabbitPrefix = rabbitPrefix.split('.').join('-')

socialQueueName = "koding-social-new-#{version}"

webPort          = 80
brokerPort       = 443
sourceServerPort = 1400
dynConfig        = JSON.parse(fs.readFileSync("#{projectRoot}/config/.dynamic-config.json"))

module.exports =
  haproxy:
    webPort     : webPort
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://new.koding.com:#{webPort}"
  userSitesDomain: 'kd.io'
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : webPort
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : no
  sourceServer  :
    enabled     : yes
    port        : sourceServerPort
  neo4j         :
    read        : "http://neo4j-dev.in.koding.com"
    write       : "http://neo4j-dev.in.koding.com"
    port        : 7474
  mongo         : mongo
  runNeo4jFeeder: no
  runGoBroker   : yes
  runKontrol    : no
  runRerouting  : yes
  compileGo     : yes
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
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    login       : 'prod-authworker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 2
    watch       : no
  cacheWorker   :
    login       : 'prod-social'
    watch       : no
    queueName   : socialQueueName+'cache'
    run         : no
  social        :
    login       : 'prod-social'
    numberOfWorkers: 10
    watch       : no
    queueName   : socialQueueName
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2
  presence      :
    exchange    : 'services-presence'
  client        :
    version     : version
    watch       : no
    watchDuration: 4000
    includesPath: 'client'
    websitePath : 'website'
    js          : "js/kd.#{version}.js"
    css         : "css/kd.#{version}.css"
    indexMaster : "index-master.html"
    index       : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://new.koding.com:#{webPort}'
    runtimeOptions:
      userSitesDomain: 'kd.io'
      useNeo4j: no
      logToExternal: no  # rollbar, mixpanel etc.
      resourceName: socialQueueName
      suppressLogs: yes
      version   : version
      mainUri   : 'http://new.koding.com:#{webPort}'
      broker    :
        sockJS  : "https://new.koding.com:#{brokerPort}/subscribe"
      apiUri    : 'https://api.koding.com'
      # Is this correct?
      appsUri   : 'https://app.koding.com'
      sourceUri : "http://new.koding.com:#{sourceServerPort}"
  mq            :
    host        : 'web-prod.in.koding.com'
    login       : 'PROD-k5it50s4676pO9O'
    port        : 5672
    apiAddress  : "web-prod.in.koding.com"
    apiPort     : 55672
    componentUser: "prod-<component>"
    password    : 'Dtxym6fRJXx4GJz'
    heartbeat   : 10
    vhost       : 'new'
  broker        :
    ip          : ""
    port        : brokerPort
    certFile    : "/etc/nginx/ssl/server_new.crt"
    keyFile     : "/etc/nginx/ssl/server_new.key"
  kites:
    disconnectTimeout: 3e3
    vhost       : 'new'
  email         :
    host        : 'koding.com'
    protocol    : 'https:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : yes
    defaultRecepient : 'chris@koding.com'
  emailSender   :
    run         : yes
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  pidFile       : '/tmp/koding.server.pid'
  loggr:
    push: no
    url: "http://post.loggr.net/1/logs/koding/events"
    apiKey: "eb65f620b72044118015d33b4177f805"
  librato:
    push: no
    email: "devrim@koding.com"
    token: "3f79eeb972c201a6a8d3461d4dc5395d3a1423f4b7a2764ec140572e70a7bce0"
    interval: 60000
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a'
