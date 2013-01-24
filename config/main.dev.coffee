fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.0.1" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect'
mongo = 'dev:GnDqQWt7iUQK4M@linus.mongohq.com:10048/koding_dev2_copy?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

rabbitPrefix = (
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e then ""
).trim()

socialQueueName = "koding-social-#{rabbitPrefix}"

module.exports = deepFreeze
  uri           :
    address     : "http://localhost:3000"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'webserver'
    port        : 3000
    clusterSize : 4
    queueName   : socialQueueName+'web'
    watch       : yes
  mongo         : mongo
  runGoBroker   : no
  compileGo     : no
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
    interval  : 30 * 1000
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
  goConfig:
    AmqpHost:     "web0.dev.system.aws.koding.com:5672"
    AmqpUser:     "broker"
    AmqpPassword: "s486auEkPzvUjYfeFTMQ"
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
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2
  presence      :
    exchange    : 'services-presence'
  client        :
    pistachios  : no
    version     : version
    minify      : no
    watch       : yes
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster: "./client/index-master.html"
    index       : "./website/index.html"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3000'
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        sockJS  : 'http://dmq.koding.com:8008/subscribe'
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
  mq            :
    host        : 'web0.dev.system.aws.koding.com'
    login       : 'guest'
    componentUser: "<component>"
    password    : 's486auEkPzvUjYfeFTMQ'
    heartbeat   : 10
    vhost       : '/'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  logger            :
    mq              :
      host          : 'web0.dev.system.aws.koding.com'
      login         : 'guest'
      password      : 's486auEkPzvUjYfeFTMQ'
  pidFile       : '/tmp/koding.server.pid'
