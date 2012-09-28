fs = require 'fs'
nodePath = require 'path'

deepFreeze = require 'koding-deep-freeze'

version = fs.readFileSync nodePath.join(__dirname, '../.revision'), 'utf-8'

mongo = 'dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect'

projectRoot = nodePath.join __dirname, '..'

rabbitVhost =\
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e then "/"

module.exports = deepFreeze
  projectRoot   : projectRoot
  version       : version
  webPort       : 3000
  mongo         : mongo
  runBroker     : no
  configureBroker: no
  buildClient   : yes
  social        :
    numberOfWorkers: 1
    watch       : yes
  client        :
    version     : version
    minify      : no
    watch       : yes
    js          : "./website/js/kd.#{version}.js"
    css         : "./website/css/kd.#{version}.css"
    indexMaster: "./client/index-master.html"
    index       : "./website/index.html"
    closureCompilerPath: "./builders/closure/compiler.jar"
    includesFile: '../CakefileIncludes.coffee'
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3020'
    runtimeOptions:
      version   : version
      mainUri   : 'http://localhost:3000'
      broker    :
        apiKey  : 'a19c8bf6d2cad6c7a006'
        sockJS  : 'http://zb.koding.com:8008/subscribe'
        auth    : 'http://localhost:3000/auth'
        vhost   : rabbitVhost
      apiUri    : 'https://dev-api.koding.com'
      appsUri   : 'https://dev-apps.koding.com'
  mq            :
    host        : 'zb.koding.com'
    login       : 'guest'
    password    : 's486auEkPzvUjYfeFTMQ'
    vhost       : rabbitVhost
    vhosts      : [
      rule      : '^secret-kite -'
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
  pidFile           : '/tmp/koding.server.pid'