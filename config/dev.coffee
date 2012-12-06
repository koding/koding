fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.0.1" #fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect'
# mongo = 'koding_stage_user:dkslkds84ddj@web0.beta.system.aws.koding.com:38017/koding_stage?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

rabbitVhost =\
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e then "/"

module.exports = deepFreeze
  uri           :
    address     : "http://localhost:3000"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    port        : [3001..3002]
  mongo         : mongo
  runBroker     : no
  configureBroker: no
  buildClient   : no
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
  loadBalancer  :
    port        : 3000
    heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo 
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  social        :
    numberOfWorkers: 1
    watch       : yes
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
      suppressLogs: no
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://zb.koding.com:8008/subscribe'
        auth    : 'http://localhost:3000/Auth'
        vhost   : rabbitVhost
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      appsUri   : 'https://dev-app.koding.com'
  mq            :
    host        : 'zb.koding.com'
    login       : 'guest'
    password    : 's486auEkPzvUjYfeFTMQ'
    vhost       : rabbitVhost
    vhosts      : [
      rule      : '^secret-kite-'
      vhost     : 'kite'
    ]
    pidFile     : '/var/run/broker.pid'
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
      host          : 'zb.koding.com'
      login         : 'guest'
      password      : 's486auEkPzvUjYfeFTMQ'
      vhost         : rabbitVhost
  vhostConfigurator:
    explanation :\
      """
      Important!  because the dev rabbitmq instance is shared, you
      need to choose a name for your vhost.  You appear not to
      have a vhost associated with this repository. Generally
      speaking, your first name is a good choice.
      """.replace /\n/g, ' '
    uri         : 'http://zb.koding.com:3008/resetVhost'
    webPort     : 3008
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
