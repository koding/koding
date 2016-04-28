traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

Configuration = (options = {}) ->

  options.domains =
    base : 'koding.com'
    mail : 'koding.com'
    main : 'sandbox.koding.com'
    port : '80'


  options.serviceHost   = "10.0.0.136"
  options.publicPort = "80"
  options.hostname = "sandbox.koding.com#{if options.publicPort is "80" then "" else ":"+options.publicPort}"
  options.protocol = "https:"
  options.publicHostname = "#{options.protocol}//#{options.hostname}"
  options.region = "aws"
  options.configName = "sandbox"
  options.environment = "sandbox"
  options.projectRoot = "/opt/koding"
  options.version or= options.tag
  options.build or= "1111"
  options.tunnelUrl or= "http://devtunnelproxy.koding.com"
  options.kiteHome or= "#{options.projectRoot}/kite_home/koding"
  options.userSitesDomain or= "sandbox.koding.io"
  options.defaultEmail or= "hello@#{options.domains.mail}"
  options.recaptchaEnabled or= yes
  options.debugGithubAPI or= no
  options.autoConfirmAccounts or= no
  options.vmwatcherConnectToKlient = yes
  options.secureCookie = yes
  options.algoliaIndexSuffix = ".sandbox"
  options.socialQueueName = "koding-social-#{options.configName}"
  options.sendEventsToSegment = yes
  options.scheme = 'https'
  options.suppressLogs = no
  options.paymentBlockDuration = 2 * 60 * 1000 # 2 minutes
  options.vaultPath or= path.join __dirname, "../../vault/"
  options.credentialPath or= path.join options.vaultPath, "./config/credentials.#{options.environment}.coffee"

  try fs.lstatSync options.credentialPath
  catch
    console.log """
      couldnt find credential in given path: #{options.credentialPath}
      please provide --vaultPath or --credentialPath while configuring
    """
    process.exit 1

  options.host = options.hostname

  options.customDomain =
    public  : "#{options.scheme}://#{options.host}"
    public_ : options.host
    local   : "http://127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    local_  : "127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    port    : parseInt(options.publicPort, 10)

  credentials = require(options.credentialPath)(options)

  worker_ci_test = require './aws/worker_ci_test_key.json'

  # if you want to disable a feature add here with "true" value do not forget to
  # add corresponding go struct properties
  # "true" value is used because of Go's default value for boolean properties is
  # false, so all the features are enabled as default, you dont have to define
  # features everywhere
  options.disabledFeatures =
    moderation : yes
    teams      : yes
    botchannel : yes

  KONFIG = require('./generateKonfig')(options, credentials)

  workers = require('./workers')(KONFIG, options, credentials)

  KONFIG.workers = require('./customextend') workers,
    gowebserver         :
      nginx             :
        locations       : [
          location      : "~^/IDE/.*"
          auth          : yes
      ]

    webserver           :
      instances         : 2
      supervisord       :
        command         : "node #{options.projectRoot}/servers/index.js -c #{options.configName} -p #{KONFIG.webserver.port} --kite-port=#{KONFIG.webserver.kitePort} --kite-key=#{options.kiteHome}/kite.key"
      nginx             :
        locations       : [
          {
            location    : "~ /-/api/(.*)"
            proxyPass   : "http://webserver/-/api/$1$is_args$args"
          }
          {
            location    : "/"
            auth        : yes
          }
        ]
    socialworker        :
      instances         : 4
      supervisord       :
        command         : "node #{options.projectRoot}/workers/social/index.js -c #{options.configName} -p #{KONFIG.social.port} -r #{options.region} --kite-port=#{KONFIG.social.kitePort} --kite-key=#{options.kiteHome}/kite.key"

    authworker          :
      group             : "webserver"
      supervisord       :
        command         : "node #{options.projectRoot}/workers/auth/index.js -c #{options.configName} -p #{KONFIG.authWorker.port}"

    sourcemaps          :
      supervisord       :
        command         : "node #{options.projectRoot}/servers/sourcemaps/index.js -c #{options.configName} -p #{KONFIG.sourcemaps.port}"

    socialapi           :
      instances         : 2

    realtime            :
      instances         : 3


  KONFIG.client.runtimeOptions = require('./generateRuntimeConfig')(KONFIG, credentials, options)

  KONFIG.supervisord =
    logdir  : '/var/log/koding'
    rundir  : '/var/run'
    minfds  : 10000
    minprocs: 200

  KONFIG.supervisord.unix_http_server =
    file: "#{KONFIG.supervisord.rundir}/supervisor.sock"

  KONFIG.supervisord.memmon =
    limit: '1536MB'
    email: 'sysops+supervisord-sandbox@koding.com'

  KONFIG.JSON = JSON.stringify KONFIG
  KONFIG.ENV = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.supervisorConf = (require "../deployment/supervisord.coffee").create KONFIG
  KONFIG.nginxConf = (require "../deployment/nginx.coffee").create KONFIG, options.environment
  KONFIG.runFile = require('./generateRunFile').sandbox(KONFIG, options, credentials)
  KONFIG.configCheckExempt = ["command", "output_path"]

  return KONFIG

module.exports = Configuration
