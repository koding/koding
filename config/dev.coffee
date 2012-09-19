fs = require 'fs'
nodePath = require 'path'

version = fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect'

module.exports =
  version   : version
  webPort   : [3020..3030]
  mongo     : mongo
  client    :
    minify  : no
    js      : "./website/js/kd.#{version}.js"
    css     : "./website/css/kd.#{version}.css"
    indexMaster: "./client/index-master.html"
    index   : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    runtimeOptions:
      version   : version
      broker    :
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://localhost:8008/subscribe'
        auth    : 'http://localhost:3020/auth'
      apiUri    : 'http://dev-api.koding.com'
      # staticFilesBaseUrl: 'http://localhost:3020'
  mq          :
    host      : 'localhost'
    login     : 'guest'
    password  : 'guest'
  email       :
    host      : 'localhost'
    protocol  : 'http:'
    defaultFromAddress: 'hello@koding.com'
  guestCleanup:
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    batchSize       : undefined
    cron            : '*/10 * * * * *'
  logger            : 
    mongo           : mongo
    collection      :'koding_logs'
  pidFile           : '/tmp/koding.server.pid'