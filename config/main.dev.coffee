traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

Configuration = (options = {}) ->

  options.domains =
    base: options.hostname ? 'koding.com'
    mail: 'koding.com'
    main: options.host ? 'dev.koding.com'
    port: '8090'

  options.boot2dockerbox or= if os.type() is "Darwin" then "192.168.59.103" else "localhost"
  options.serviceHost = options.boot2dockerbox
  options.publicPort or= "8090"
  options.hostname or= "dev.koding.com"
  options.protocol or= "http:"
  options.publicHostname or= "#{options.protocol}//#{options.hostname}"
  options.region or= "dev"
  options.configName or= "dev"
  options.environment or= "dev"
  options.projectRoot or= path.join __dirname, '/..'
  options.version or= "2.0" # TBD
  options.build or= "1111"
  options.tunnelHostedZoneName = "dev-t.koding.com"
  options.tunnelHostedZoneCallerRef = "devtunnelproxy_hosted_zone_v0"
  options.tunnelserverHostedZone or= "dev.koding.me"
  options.tunnelserverBasevirtualHost or= "dev.koding.me"
  options.tunnelUrl or= "http://#{options.tunnelHostedZoneName}"
  options.userSitesDomain or= "dev.koding.io"
  options.defaultEmail or= "hello@#{options.domains.mail}"
  options.recaptchaEnabled or= no
  options.debugGithubAPI or= yes
  options.autoConfirmAccounts or= yes
  options.vmwatcherConnectToKlient = no
  options.secureCookie = no
  options.algoliaIndexSuffix = ".#{ os.hostname() }"
  options.socialQueueName = "koding-social-#{options.configName}"
  options.sendEventsToSegment = yes
  options.scheme = 'http'
  options.suppressLogs = no
  options.paymentBlockDuration = 2 * 60 * 1000 # 2 minutes
  options.vaultPath or= path.join __dirname, "../vault/" # use same directory with our application
  options.credentialPath or= path.join options.vaultPath, "./config/credentials.#{options.config}.coffee"
  options.clientUploadS3BucketName = 'kodingdev-client'

  try fs.lstatSync options.credentialPath
  catch
    console.log """
      couldnt find credential in given path: #{options.credentialPath}
      please provide --vaultPath while configuring
    """
    process.exit 1

  _port  = if options.publicPort is '80' then '' else options.publicPort
  options.host   or= options.host or "#{options.hostname}:#{_port}"

  options.customDomain =
    public  : "#{options.scheme}://#{options.host}"
    public_ : options.host
    local   : "http://127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    local_  : "127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    port    : parseInt(options.publicPort, 10)

  credentials = require(options.credentialPath)(options)

  worker_ci_test = require path.join(options.vaultPath, './config/aws/worker_ci_test_key.json')

  # if you want to disable a feature add here with "true" value do not forget to
  # add corresponding go struct properties
  # "true" value is used because of Go's default value for boolean properties is
  # false, so all the features are enabled as default, you dont have to define
  # features everywhere
  options.disabledFeatures =
    moderation : yes
    teams      : no
    botchannel : yes
    gitlab     : no

  KONFIG = require('./generateKonfig')(options, credentials)
  KONFIG.workers = require('./workers')(KONFIG, options, credentials)
  KONFIG.client.runtimeOptions = require('./generateRuntimeConfig')(KONFIG, credentials, options)

  options.requirementCommands = [
    "$KONFIG_PROJECTROOT/scripts/generate-kite-keys.sh"
  ]

  KONFIG.supervisord =
    logdir   : "$KONFIG_PROJECTROOT/.logs"
    rundir   : "$KONFIG_PROJECTROOT/.supervisor"
    minfds   : 1024
    minprocs : 200

  KONFIG.supervisord.unix_http_server =
    file : "#{KONFIG.supervisord.rundir}/supervisor.sock"

  (require './inheritEnvVars') KONFIG  if options.inheritEnvVars

  envFiles =
    sh: (require './generateShellEnv').create KONFIG, options
    json: JSON.stringify KONFIG, null, 2

  KONFIG.supervisorConf = (require "../deployment/supervisord.coffee").create KONFIG
  KONFIG.nginxConf = (require "../deployment/nginx.coffee").create KONFIG, options.environment
  KONFIG.runFile = (require './generateRunFile').dev KONFIG, options
  KONFIG.configCheckExempt = []

  KONFIG.envFiles = envFiles

  return KONFIG

module.exports = Configuration
