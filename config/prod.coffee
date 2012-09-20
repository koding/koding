fs = require 'fs'
nodePath = require 'path'

version = fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost:27017/beta_koding?auto_reconnect'

module.exports =
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
    index       : "./website_nonstatic/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    runtimeOptions:
      version   : version
      mainUri   : 'https://dev.koding.com'
      broker    :
        apiKey  : 'a6f121a130a44c7f5325'
        sockJS  : 'https://mq.koding.com/subscribe'
        auth    : 'https://dev.koding.com/auth'
      apiUri    : 'https://dev.koding.com'
      # staticFilesBaseUrl: 'http://localhost:3020'
  mq            :
    host        : 'localhost'
    login       : 'guest'
    password    : 'x1srTA7!%Vb}$n|S'
    vhost       : '/'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guestCleanup:
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    batchSize   : undefined
    cron        : '*/10 * * * * *'
  logger        :
    mq          :
      host      : 'localhost'
      login     : 'logger'
      password  : 'logger'
      vhost     : 'logs'
  pidFile       : '/tmp/koding.server.pid'
