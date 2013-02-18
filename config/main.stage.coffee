fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.9.9a" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

domainName = "stage.aws.koding.com"

mongo = 'PROD-koding:34W4BXx595ib3J72k5Mh@db-m0.stage.aws.koding.com:27017/beta_koding'

projectRoot = nodePath.join __dirname, '..'

# rabbitPrefix = (
#   try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
#   catch e then ""
# ).trim()

socialQueueName = "koding-social-autoscale"

module.exports = deepFreeze
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "https://www.#{domainName}"
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
  watchGoBroker : yes
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
    numberOfWorkers: 2
    watch       : yes
  social        :
    login       : 'prod-social'
    numberOfWorkers: 2
    watch       : yes
    queueName   : socialQueueName
  cacheWorker   :
    login       : 'prod-social'
    watch       : yes
    queueName   : socialQueueName+'cache'
    run         : yes
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
    staticFilesBaseUrl: "https://www.#{domainName}/"
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : "https://www.#{domainName}/"
      broker    :
        sockJS  : "https://mq.#{domainName}/subscribe"
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
  mq            :
    host        : "rabbit.#{domainName}"
    login       : 'PROD-k5it50s4676pO9O'
    componentUser: "prod-<component>"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 10
    vhost       : '/'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'koding.com'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    defaultRecepient : "gokmen+emailworkerstage@koding.com"
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  logger            :
    mq              :
      host          : "rabbit.#{domainName}"
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
    interval: 60000
