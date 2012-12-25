fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.9.7e" # fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

# PROD
mongo = 'PROD-koding:34W4BXx595ib3J72k5Mh@localhost:27017/beta_koding?auto_reconnect'

module.exports = deepFreeze
#  basicAuth     :
#    username    : 'koding'
#    password    : '314159'
  uri           : 
    address     : "https://koding.com"
  monit         :
    webCake     : '/var/run/node/webCake.pid'
    kiteCake    : '/var/run/node/kiteCake.pid'
  projectRoot   : nodePath.join __dirname, '..'
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : [3020..3030]
  mongo         : mongo
  misc          :
    updateAllSlugs : no
  uploads       :
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccessKeyId      : 'AKIAIBHGXKRDSOQZESGQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  runBroker     : no
  runGoBroker   : yes
  configureBroker: no
  buildClient   : no
  loadBalancer  :
   port        : 8080
   heartbeat   : 5000
   httpRedirect:
     port      : 80 # requires sudo on macs
  social        :
    login       : 'prod-social'
    numberOfWorkers: 10
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2  
  client        :
    pistachios  : yes
    version     : version
    minify      : yes
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster : "./client/index-master.html"
    index       : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'https://api.koding.com'
    runtimeOptions:
      suppressLogs: yes
      version   : version
      mainUri   : 'https://koding.com'
      broker    :
        apiKey  : 'a6f121a130a44c7f5325'
        sockJS  : 'https://mq.koding.com/subscribe'
        auth    : 'https://koding.com/Auth'
        vhost   : '/'
      apiUri    : 'https://api.koding.com'
      appsUri   : 'https://app.koding.com'
      env       : 'beta'
  mq            :
    host        : 'localhost'
    login       : 'PROD-k5it50s4676pO9O'
    password    : 'Dtxym6fRJXx4GJz'
    vhost       : 'slugs'
    pidFile     : '/var/run/broker.pid'
  kites:
    disconnectTimeout: 3e3
  email         :
    host        : 'koding.com'
    protocol    : 'https:'
    defaultFromAddress: 'hello@koding.com'
  guests:
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    batchSize   : undefined
    cleanupCron : '*/10 * * * * *'
    poolSize    : 1e4
  mixpanel :
    key : "bb9dd21f58e3440e048a2c907422deed"
  librato:
    push: yes
    email: "devrim@koding.com"
    token: "3f79eeb972c201a6a8d3461d4dc5395d3a1423f4b7a2764ec140572e70a7bce0"
    interval: 30000
  logger        :
    mq          :
      host      : 'localhost'
      login     : 'PROD-k5it50s4676pO9O'
      password  : 'Dtxym6fRJXx4GJz'
      vhost     : '/'
  pidFile       : '/tmp/koding.server.pid'
