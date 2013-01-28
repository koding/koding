fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.9.9a" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:GnDqQWt7iUQK4M@miles.mongohq.com:10057/koding_dev2?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

# rabbitPrefix = (
#   try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
#   catch e then ""
# ).trim()

socialQueueName = "koding-social-autoscale"

module.exports = deepFreeze
  uri           :
    address     : "http://devrim.dev.service.aws.koding.com"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3020
    clusterSize : 2
    queueName   : socialQueueName+'web'
    watch       : yes
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
    distribution: 'http://d2mehr5c6bceom.cloudfront.net'
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
  goConfig:
    HomePrefix:   "/Users/"
    UseLVE:       true
  authWorker    :
    login       : 'prod-auth-worker'
    queueName   : socialQueueName+'auth'
    authResourceName: 'auth'
    numberOfWorkers: 1
    watch       : yes
  social        :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 1
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
    staticFilesBaseUrl: 'http://as.koding.com/'
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : 'http://devrim.dev.service.aws.koding.com/'
      broker    :
        sockJS  : 'http://broker.devrim.dev.service.aws.koding.com:8008/subscribe'
      apiUri    : 'http://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'http://dev-app.koding.com'
  mq            :
    host        : 'mq.devrim.dev.service.aws.koding.com'
    login       : 'PROD-k5it50s4676pO9O'
    componentUser: "prod-<component>"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 10
    vhost       : '/'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'as.koding.com'
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
      host          : 'mq.devrim.dev.service.aws.koding.com'
      login         : 'guest'
      password      : 's486auEkPzvUjYfeFTMQ'
  pidFile       : '/tmp/koding.server.pid'
  loggr:
    push: no
    url: ""
    apiKey: ""
  librato:
    push: no
    email: ""
    token: ""
    interval: 30000
