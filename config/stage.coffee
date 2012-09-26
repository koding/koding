fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

# STAGING
mongo = 'koding_stage_user:dkslkds84ddj@localhost:38017/koding_stage?auto_reconnect'

module.exports = deepFreeze
  projectRoot   : nodePath.join __dirname, '..'
  version       : version
  webPort       : [3020..3030]
  mongo         : mongo
  runBroker     : no
  configureBroker: no
  buildClient   : no
  social        :
    numberOfWorkers: 10
  client        :
    version     : version
    minify      : no
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster : "./client/index-master.html"
    index       : "./website_nonstatic/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'https://api.koding.com'
    runtimeOptions:
      version   : version
      mainUri   : 'https://dev.koding.com'
      broker    :
        apiKey  : 'a6f121a130a44c7f5325'
        sockJS  : 'http://web0.beta.system.aws.koding.com:8008/subscribe'
        auth    : 'https://dev.koding.com/auth'
      apiUri    : 'https://dev-api.koding.com'
      appsUri   : 'https://apps.koding.com'
      env       : 'dev'
  mq            :
    host        : 'localhost'
    login       : 'stage'
    password    : '#[85_[*zh7%4;4l6T]F!'
    vhost       : 'stage'
  kites:
    disconnectTimeout: 3e3
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guests:
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    batchSize   : undefined
    cleanupCron : '*/10 * * * * *'
    poolSize    : 1e4
  logger        :
    mq          :
      host      : 'localhost'
      login     : 'stage'
      password  : '#[85_[*zh7%4;4l6T]F!'
      vhost     : 'stage-logs'
  pidFile       : '/tmp/koding.server.pid'
