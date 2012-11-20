fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.0.1"

# DEV database
mongo = 'dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

#rabbitVhost = try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf-8'

module.exports = deepFreeze
  projectRoot   : projectRoot
  version       : version
  webserver     :
    port        : 3000
  mongo         : mongo
  uploads       :
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccountId        : '616271189586'
      awsAccessKeyId      : 'AKIAJO74E23N33AFRGAQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  buildClient   : yes
  social        :
    numberOfWorkers: 1
    watch       : yes
  feeder        :
    queueName   : "koding-feeder"
    exchangePrefix: "followable-"
    numberOfWorkers: 2
  client        :
    version     : version
    minify      : no
    watch       : yes
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster : "./client/index-master.html"
    index       : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3000'
    runtimeOptions:
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://localhost:8008/subscribe'
        auth    : 'http://localhost:3000/Auth'
        vhost   : '/'
      apiUri    : 'https://dev-api.koding.com'
      appsUri   : 'http://dev-app.koding.com'
      env       : 'dev'
      # staticFilesBaseUrl: 'http://localhost:3020'
  mq            :
    host        : 'localhost'
    login       : 'guest'
    password    : 'guest'
    vhost       : '/'
    pidFile     : '/tmp/koding.broker.pid'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize    : 1e4
    batchSize   : undefined
    cleanupCron : '*/10 * * * * *'
  logger        :
    mq          :
      host      : 'localhost'
      login     : 'guest'
      password  : 'guest'
      vhost     : '/'
  pidFile       : '/tmp/koding.server.pid'
