fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

# PROD
mongo = 'mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost:27017/beta_koding?auto_reconnect'

module.exports = deepFreeze
  projectRoot   : nodePath.join __dirname, '..'
  version       : version
  webPort       : [3020..3030]
  mongo         : mongo
  social        :
    numberOfWorkers: 10
  client        :
    version     : version
    minify      : no
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster : "./client/index-master.html"
    index       : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'https://api.koding.com'
    runtimeOptions:
      version   : version
      mainUri   : 'https://dev.koding.com'
      broker    :
        apiKey  : 'a6f121a130a44c7f5325'
#        sockJS  : 'http://web0.beta.system.aws.koding.com:8008/subscribe'
        sockJS  : 'https://mq.koding.com/subscribe'
        auth    : 'https://dev.koding.com/auth'
      apiUri    : 'https://api.koding.com'
      env       : 'beta'
  mq            :
    host        : 'localhost'
    login       : 'guest'
    password    : 'x1srTA7!%Vb}$n|S'
    vhost       : '/'
    pidFile     : '/tmp/koding.broker.pid'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guestCleanup  :
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    poolSize    : 1e4
    batchSize   : undefined
    cron        : '*/10 * * * * *'
  logger        :
    mq          :
      host      : 'localhost'
      login     : 'logger'
      password  : 'logger'
      vhost     : 'logs'
  pidFile       : '/tmp/koding.server.pid'
