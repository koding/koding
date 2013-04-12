fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

version         = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()
mongo           = 'dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy'

projectRoot     = nodePath.join __dirname, '..'
rabbitPrefix    = require "#{projectRoot}/utils/rabbitPrefix"
socialQueueName = "koding-social-#{rabbitPrefix}"

webPort         = 3000
brokerPort      = 8000 + (version % 10)
dynConfig       = JSON.parse(fs.readFileSync("#{projectRoot}/config/.dynamic-config.json"))

module.exports = deepFreeze
  haproxy:
    webPort     : webPort
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://localhost:#{webPort}"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'webserver'
    port        : dynConfig.webInternalPort
    clusterSize : 4
    queueName   : socialQueueName+'web'
    watch       : yes
  sourceServer  :
    enabled     : no
    port        : 1337
  mongo         : mongo
  runGoBroker   : yes
  compileGo     : yes
  buildClient   : yes
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
  goConfig:
    HomePrefix:   "/Users/"
    UseLVE:       true
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    login       : 'authWorker'
    queueName   : socialQueueName+'auth'
    authResourceName: 'auth'
    numberOfWorkers: 1
    watch       : yes
  social        :
    login       : 'social'
    numberOfWorkers: 4
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
    includesPath: 'client'
    websitePath : 'website'
    js          : "js/kd.#{version}.js"
    css         : "css/kd.#{version}.css"
    indexMaster : "index-master.html"
    index       : "index.html"
    useStaticFileServer: no
    staticFilesBaseUrl: "http://localhost:3000"
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : "http://localhost:#{webPort}"
      broker    :
        sockJS  : "http://localhost:#{brokerPort}/subscribe"
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
      sourceUri : 'http://localhost:1337'
  mq            :
    host        : 'localhost'
    login       : 'guest'
    componentUser: "<component>"
    password    : 'guest'
    heartbeat   : 10
    vhost       : '/'
  broker        :
    port        : brokerPort
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
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  logger            :
    mq              :
      host          : 'localhost'
      login         : 'guest'
      password      : 'guest'
  pidFile       : '/tmp/koding.server.pid'
