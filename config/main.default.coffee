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

  options.serviceHost or= '127.0.0.1'
  options.publicPort or= '8090'
  options.hostname or= 'dev.koding.com'
  options.protocol or= 'http:'
  options.publicHostname or= "#{options.protocol}//#{options.hostname}"
  options.region or= 'default'
  options.configName or= 'default'
  options.environment or= 'default'
  options.ebEnvName = options.environment
  options.projectRoot or= path.join __dirname, '/..'
  options.tunnelHostedZoneName = 'dev-t.koding.com'
  options.tunnelHostedZoneCallerRef = 'devtunnelproxy_hosted_zone_v0'
  options.tunnelserverHostedZone or= 'dev.koding.me'
  options.tunnelserverBasevirtualHost or= 'dev.koding.me'
  options.tunnelUrl or= "http://#{options.tunnelHostedZoneName}"
  options.userSitesDomain or= 'dev.koding.io'
  options.defaultEmail or= "hello@#{options.domains.mail}"
  options.recaptchaEnabled or= no
  options.debugGithubAPI or= yes
  options.autoConfirmAccounts or= yes
  options.secureCookie = no
  options.socialQueueName = "koding-social-#{options.configName}"
  options.sendEventsToSegment = yes
  options.scheme = 'http'
  options.suppressLogs = no
  options.credentialPath or= "$KONFIG_PROJECTROOT/config/credentials.#{options.environment}.coffee"
  options.clientUploadS3BucketName or= 'kodingdev-client'
  options.publicLogsS3BucketName or= 'kodingdev-publiclogs'
  options.userProxyHost or= options.hostname
  options.userProxyUri or= "#{options.userProxyHost}/-/devproxy"
  options.userTunnelUri or= "#{options.userProxyHost}/-/devtunnel"

  _port = if options.publicPort is '80' then '' else ":#{options.publicPort}"
  options.host or= "#{options.hostname}#{_port}"

  customDomain =
    public  : "#{options.scheme}://#{options.host}"
    public_ : options.host
    local   : "http://127.0.0.1#{_port}"
    local_  : "127.0.0.1#{_port}"
    port    : parseInt(options.publicPort, 10)

  options.customDomain = customDomain
  credentials = require("./credentials.#{options.environment}")(options)
  worker_ci_test = require './aws/worker_ci_test_key.json'

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

  options.enabledWorkers = [
    'notification'
    'emailer'
  ]

  options.disabledWorkers = [
    'gatekeeper'
    'dispatcher'
  ]

  KONFIG = require('./generateKonfig')(options, credentials)
  (require './inheritEnvVars') KONFIG  if options.inheritEnvVars
  KONFIG.workers = require('./workers')(KONFIG, options, credentials)
  KONFIG.client.runtimeOptions = require('./generateRuntimeConfig')(KONFIG, credentials, options)

  # Disable Sneaker for kloud.
  KONFIG.kloud.noSneaker = true

  endpoint = "#{options.protocol}//#{options.domains.main}"
  KONFIG.goKoding.endpoints.ip.public = "#{endpoint}/-/ip"
  KONFIG.goKoding.endpoints.ipCheck.public = "#{endpoint}/-/ipCheck"
  KONFIG.goKoding.endpoints.kdLatest.public = "#{endpoint}/a/kd/#{options.environment}/latest-version.txt"
  KONFIG.goKoding.endpoints.klientLatest.public = "#{endpoint}/a/klient/#{options.environment}/latest-version.txt"

  options.requirementCommands = [
    '$KONFIG_PROJECTROOT/scripts/generate-kite-keys.sh'
  ]

  KONFIG.supervisord =
    logdir   : '$KONFIG_PROJECTROOT/.logs'
    rundir   : '$KONFIG_PROJECTROOT/.supervisor'
    minfds   : 1024
    minprocs : 200

  KONFIG.supervisord.unix_http_server =
    file : "#{KONFIG.supervisord.rundir}/supervisor.sock"

  envFiles =
    sh: (require './generateShellEnv').create KONFIG, options
    json: JSON.stringify KONFIG, null, 2

  KONFIG.supervisorConf = (require '../deployment/supervisord.coffee').create KONFIG
  KONFIG.nginxConf = (require '../deployment/nginx.coffee').create KONFIG, options.environment
  KONFIG.runFile = (require './generateRunFile').default KONFIG, options
  KONFIG.configCheckExempt = []

  KONFIG.envFiles = envFiles

  return KONFIG

module.exports = Configuration
