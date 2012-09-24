fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = "0.0.1"

mongo = 'dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect'

module.exports = deepFreeze
  projectRoot: nodePath.join __dirname, '..'
  version   : version
  webPort   : 3000
  mongo     : mongo
  social    :
    numberOfWorkers: 1
  client    :
    version : version
    minify  : no
    watch   : yes
    js      : "./website/js/kd.#{version}.js"
    css     : "./website/css/kd.#{version}.css"
    indexMaster: "./client/index-master.html"
    index   : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer : no
    staticFilesBaseUrl: 'http://localhost:3020'
    runtimeOptions:
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://localhost:8008/subscribe'
        auth    : 'http://localhost:3000/auth'
      apiUri    : 'https://dev-api.koding.com'
      appsUri   : 'https://dev-apps.koding.com'

  mq            :
    host        : 'localhost'
    login       : 'guest'
    password    : 'guest'
    vhost       : '/'
    pidFile     : '/var/run/broker.pid'
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
      vhost         : '/'
  pidFile           : '/tmp/koding.server.pid'