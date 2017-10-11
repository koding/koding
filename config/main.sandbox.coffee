traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

Configuration = (options = {}) ->

  options.domains =
    base: 'koding.com'
    mail: 'koding.com'
    main: 'sandbox.koding.com'
    port: '80'

  options.serviceHost or= '10.0.0.23'
  options.publicPort = '80'
  options.hostname = "sandbox.koding.com#{if options.publicPort is '80' then '' else ':'+options.publicPort}"
  options.protocol = 'https:'
  options.publicHostname = "#{options.protocol}//#{options.hostname}"
  options.region = 'aws'
  options.configName = 'sandbox'
  options.environment = 'sandbox'
  options.projectRoot = '/opt/koding'
  options.tunnelHostedZoneName = 'dev-t.koding.com'
  options.tunnelHostedZoneCallerRef = 'devtunnelproxy_hosted_zone_v0'
  options.tunnelserverHostedZone or= 'dev.koding.me'
  options.tunnelserverBasevirtualHost or= 'dev.koding.me'
  options.tunnelUrl or= "http://#{options.tunnelHostedZoneName}"
  options.userSitesDomain or= 'sandbox.koding.io'
  options.defaultEmail or= "hello@#{options.domains.mail}"
  options.recaptchaEnabled or= yes
  options.debugGithubAPI or= no
  options.autoConfirmAccounts or= no
  options.secureCookie = yes
  options.socialQueueName = "koding-social-#{options.configName}"
  options.sendEventsToSegment = yes
  options.scheme = 'https'
  options.suppressLogs = no
  options.vaultPath or= path.join __dirname, '../vault/' # use same directory with our application
  options.credentialPath or= path.join options.vaultPath, "./config/credentials.#{options.environment}.coffee"
  options.clientUploadS3BucketName = 'kodingdev-client'
  options.publicLogsS3BucketName or= 'kodingdev-publiclogs'
  options.proxySubdomain or= 'dev-p'
  options.userProxyHost or= "#{options.proxySubdomain}.koding.com"
  options.userProxyUri or= "#{options.userProxyHost}/-/devproxy"
  options.userTunnelUri or= "#{options.userProxyHost}/-/devtunnel"


  try fs.lstatSync options.credentialPath
  catch
    console.log """
      couldnt find credential in given path: #{options.credentialPath}
      please provide --vaultPath while configuring
    """
    process.exit 1

  options.host = options.hostname

  options.customDomain =
    public  : "#{options.scheme}://#{options.host}"
    public_ : options.host
    local   : "http://127.0.0.1#{if options.publicPort is '80' then '' else ':' + options.publicPort}"
    local_  : "127.0.0.1#{if options.publicPort is '80' then '' else ':' + options.publicPort}"
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
    teams      : yes
    botchannel : yes
    gitlab     : yes

  KONFIG = require('./generateKonfig')(options, credentials)

  (require './inheritEnvVars') KONFIG  if options.inheritEnvVars

  workers = require('./workers')(KONFIG, options, credentials)

  KONFIG.workers = require('./customextend') workers,
    webserver           :
      instances         : 2
      supervisord       :
        command         : "node %(ENV_KONFIG_PROJECTROOT)s/servers/index.js -p #{KONFIG.webserver.port} --kite-port=#{KONFIG.webserver.kitePort}"

    socialworker        :
      instances         : 4
      supervisord       :
        command         : "node %(ENV_KONFIG_PROJECTROOT)s/workers/social/index.js -p #{KONFIG.social.port} --kite-port=#{KONFIG.social.kitePort}"

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

  envFiles =
    sh: (require './generateShellEnv').create KONFIG, options
    json: JSON.stringify KONFIG, null, 2

  KONFIG.supervisorConf = (require '../deployment/supervisord.coffee').create KONFIG
  KONFIG.nginxConf = (require '../deployment/nginx.coffee').create KONFIG, options.environment
  KONFIG.runFile = (require './generateRunFile').sandbox KONFIG, options
  KONFIG.configCheckExempt = ['command', 'output_path']

  KONFIG.envFiles = envFiles

  return KONFIG

module.exports = Configuration
