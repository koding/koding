fs = require 'fs'
nodePath = require 'path'

version = "0.0.1" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:k9lc4G1k32nyD72@web0.dev.system.aws.koding.com:27017/koding_dev2_copy'
# mongo = 'dev:GnDqQWt7iUQK4M@linus.mongohq.com:10048/koding_dev2_copy'
#mongo = 'dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2'
# mongo = 'koding_stage_user:dkslkds84ddj@web0.beta.system.aws.koding.com:38017/koding_stage'

projectRoot = nodePath.join __dirname, '..'

rabbitPrefix = (
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e then ""
).trim()

socialQueueName = "koding-social-#{rabbitPrefix}"

module.exports =
  uri           :
    address     : "http://localhost:3000"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'webserver'
    port        : 3000
    clusterSize : 4
    queueName   : socialQueueName+'web'
  mongo         : mongo
  runGoBroker   : yes
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
    login       : 'authWorker'
    queueName   : socialQueueName+'auth'
    authResourceName: 'auth'
    numberOfWorkers: 1
  social        :
    login       : 'social'
    numberOfWorkers: 4
    watch       : yes
    queueName   : socialQueueName
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2
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
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://dmq.koding.com:8008/subscribe'
        vhost   : '/'
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
  mq            :
    host        : 'localhost'
    login       : 'guest'
    password    : 'guest'
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
      host          : 'localhost'
      login         : 'guest'
      password      : 'guest'
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
