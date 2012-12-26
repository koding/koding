fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.9.9" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect'
# mongo = 'koding_stage_user:dkslkds84ddj@web0.beta.system.aws.koding.com:38017/koding_stage?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

# rabbitPrefix = (
#   try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
#   catch e then ""
# ).trim()

socialQueueName = "koding-social-prod"

module.exports = deepFreeze
  uri           :
    address     : "http://localhost:3000"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3000
    clusterSize : 4
    queueName   : socialQueueName+'web'
  mongo         : mongo
  runGoBroker   : no
  buildClient   : yes
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    # debugConnectionErrors: yes
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
    authResourceName: 'auth'
    numberOfWorkers: 1
  social        :
    login       : 'prod-social'
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
    pistachios  : yes
    version     : version
    minify      : yes
    watch       : no
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster: "./client/index-master.html"
    index       : "./website/index.html"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'https://koding.com'
    runtimeOptions:
      resourceName: socialQueueName
      suppressLogs: yes
      version   : version
      mainUri   : 'https://koding.com'
      broker    :
        sockJS  : 'https://mq.koding.com:8008/subscribe'
        vhost   : '/'
      apiUri    : 'https://api.koding.com'
      # Is this correct?
      appsUri   : 'https://app.koding.com'
  mq            :
    host        : 'web0.prod.system.aws.koding.com'
    login       : 'PROD-k5it50s4676pO9O'
    password    : 'Dtxym6fRJXx4GJz'
    heartbeat   : 10
    vhost       : '/'
  kites:
    disconnectTimeout: 3e3
    vhost       : '/'
  email         :
    host        : 'koding.com'
    protocol    : 'https:'
    defaultFromAddress: 'hello@koding.com'
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  logger            :
    mq              :
      host          : 'web0.prod.system.aws.koding.com'
      login         : 'PROD-k5it50s4676pO9O'
      password      : 'Dtxym6fRJXx4GJz'
  pidFile       : '/tmp/koding.server.pid'
  mixpanel :
    key : "bb9dd21f58e3440e048a2c907422deed"
  crypto :
    encrypt: (str,key=Math.floor(Date.now()/1000/60))->
      crypto = require "crypto"
      str = str+""
      key = key+""
      cipher = crypto.createCipher('aes-256-cbc',""+key)
      cipher.update(str,'utf-8')
      a = cipher.final('hex')
      return a
    decrypt: (str,key=Math.floor(Date.now()/1000/60))->
      crypto = require "crypto"
      str = str+""
      key = key+""
      decipher = crypto.createDecipher('aes-256-cbc',""+key)
      decipher.update(str,'hex')
      b = decipher.final('utf-8')
      return b
