traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

Configuration = (options={}) ->
  prod_simulation_server = "10.0.0.136"
  options.domains =
    base : 'koding.com'
    mail : 'koding.com'
    main : 'sandbox.koding.com'
    port : '80'

  options.boot2dockerbox or= if os.type() is "Darwin" then "192.168.59.103" else "localhost"
  options.serviceHost   = prod_simulation_server
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

  options.host = options.hostname
  # if options.ngrok
  #   options.scheme = 'https'
  #   options.host   = "koding-#{process.env.USER}.ngrok.com"
  # else
  #   options.scheme = 'http'
  #   _port  = if options.publicPort is '80' then '' else options.publicPort
  #   options.host   = options.host or "#{options.hostname}:#{_port}"
  customDomain =
    public  : "#{options.scheme}://#{options.host}"
    public_ : options.host
    local   : "http://127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    local_  : "127.0.0.1#{if options.publicPort is "80" then "" else ":" + options.publicPort}"
    port    : parseInt(options.publicPort, 10)
    host    : options.hostname


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
    teams      : yes
    botchannel : yes

  KONFIG = require('./generateKonfig')(options, credentials)

  workers = require('./workers')(KONFIG, options, credentials)

  KONFIG.workers = require('./customextend') workers,
    webserver           :
      instances         : 2
      supervisord       :
        command         : "node #{options.projectRoot}/servers/index.js -c #{options.configName} -p #{KONFIG.webserver.port} --disable-newrelic --kite-port=#{KONFIG.webserver.kitePort} --kite-key=#{options.kiteHome}/kite.key"
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
        command         : "node #{options.projectRoot}/workers/social/index.js -c #{options.configName} -p #{KONFIG.social.port} -r #{options.region} --disable-newrelic --kite-port=#{KONFIG.social.kitePort} --kite-key=#{options.kiteHome}/kite.key"

    authworker          :
      group             : "webserver"
      supervisord       :
        command         : "node #{options.projectRoot}/workers/auth/index.js -c #{options.configName} -p #{KONFIG.authWorker.port} --disable-newrelic"

    sourcemaps          :
      supervisord       :
        command         : "node #{options.projectRoot}/servers/sourcemaps/index.js -c #{options.configName} -p #{KONFIG.sourcemaps.port} --disable-newrelic"

    socialapi           :
      instances         : 2

    realtime            :
      instances         : 3


  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  # NOTE: when you add to runtime options below, be sure to modify
  # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`
  KONFIG.client.runtimeOptions =
    kites                : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    algolia              : { appId: credentials.algolia.appId, indexSuffix: options.algoliaIndexSuffix }
    suppressLogs         : no
    authExchange         : "auth"
    environment          : options.environment                        # this is where browser knows what kite environment to query for
    version              : options.version
    resourceName         : options.socialQueueName
    userSitesDomain      : options.userSitesDomain
    socialApiUri         : "/xhr"
    apiUri               : "/"
    sourceMapsUri        : "/sourcemaps"
    mainUri              : "/"
    broker               : { uri: "/subscribe" }
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    fileFetchTimeout     : 1000 * 15
    userIdleMs           : 1000 * 60 * 5
    embedly              : {apiKey       : KONFIG.embedly.apiKey}
    github               : {clientId     : credentials.github.clientId}
    sessionCookie        : KONFIG.sessionCookie
    troubleshoot         : {idleTime     : 1000 * 60 * 60, externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    stripe               : { token: 'pk_test_2x9UxMl1EBdFtwT5BRfOHxtN' }
    externalProfiles     :
      google             : { nicename: 'Google' }
      linkedin           : { nicename: 'LinkedIn'}
      twitter            : { nicename: 'Twitter' }
      odesk              : { nicename: 'Upwork', urlLocation: 'info.profile_url' }
      facebook           : { nicename: 'Facebook', urlLocation: 'link' }
      github             : { nicename: 'GitHub', urlLocation: 'html_url' }
    entryPoint           : { slug:'koding'     , type:'group' }
    siftScience          : '91f469711c'
    paypal               : { formUrl: 'https://www.sandbox.paypal.com/incontext' }
    pubnub               : { subscribekey: credentials.pubnub.subscribekey , ssl: yes,  enabled: yes    }
    collaboration        : KONFIG.collaboration
    paymentBlockDuration : 2 * 60 * 1000 # 2 minutes
    tokbox               : { apiKey: credentials.tokbox.apiKey }
    disabledFeatures     : options.disabledFeatures
    integration          : { url: "#{KONFIG.integration.url}" }
    webhookMiddleware    : { url: "#{KONFIG.socialapi.webhookMiddleware.url}" }
    google               : apiKey: 'AIzaSyDiLjJIdZcXvSnIwTGIg0kZ8qGO3QyNnpo'
    recaptcha            : { enabled : KONFIG.recaptcha.enabled, key : "6Ld8wwkTAAAAAArpF62KStLaMgiZvE69xY-5G6ax" }
    sendEventsToSegment  : KONFIG.sendEventsToSegment
    domains              : options.domains
    contentRotatorUrl    : 'http://koding.github.io'

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

  keys = Object.keys(KONFIG)
  len = keys.length

  keys.sort()

  s = []
  for i in keys
    k = keys[i]
    s.push KONFIG[i]

  console.log JSON.stringify s


  KONFIG.JSON            = JSON.stringify KONFIG
  KONFIG.ENV             = (require "../deployment/envvar.coffee").create KONFIG
  KONFIG.supervisorConf  = (require "../deployment/supervisord.coffee").create KONFIG
  KONFIG.nginxConf       = (require "../deployment/nginx.coffee").create KONFIG, options.environment
  KONFIG.runFile        = require('./generateRunFile').sandbox(KONFIG, options, credentials)
  KONFIG.configCheckExempt = ["ngrokProxy", "command", "output_path"]

  return KONFIG

module.exports = Configuration
