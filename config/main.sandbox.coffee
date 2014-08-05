fs = require 'fs'
nodePath = require 'path'
deepFreeze = require 'koding-deep-freeze'

version = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()
projectRoot = nodePath.join __dirname, '..'

socialQueueName = "koding-social-#{version}"
logQueueName    = socialQueueName+'log'

authExchange    = "auth-#{version}"
authAllExchange = "authAll-#{version}"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

environment     = "sandbox"
regions         =
  vagrant       : "vagrant"
  sj            : "sj"
  aws           : "aws"
  premium       : "sj"

cookieMaxAge = 1000 * 60 * 60 * 24 * 14 # two weeks
cookieSecure = no

module.exports =
  environment   : environment
  regions       : regions
  version       : version
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://sandbox.koding.com"
  userSitesDomain: 'sandbox.kd.io'
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms-sandbox"
  projectRoot   : projectRoot
  webserver     :
    useCacheHeader: yes
    login       : 'prod-webserver'
    port        : 80
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : no
  socialapi:
    port        : 7000
    clusterSize : 1
    proxyUrl    : "http://sandbox-social.sj.koding.com:7000"
  sourceServer  :
    enabled     : no
    port        : 1337
  mongo         : 'dev:k9lc4G1k32nyD72@172.16.10.36:27017/koding'
  mongoKontrol  : 'dev:k9lc4G1k32nyD72@172.16.10.36:27017/kontrol'
  mongoReplSet  : null
  mongoMinWrites: 1
  runGoBroker   : no
  runGoBrokerKite: no
  runPremiumBrokerKite: no
  runPremiumBroker: no
  runKontrol    : yes
  runRerouting  : yes
  compileGo     : no
  buildClient   : yes
  runOsKite     : no
  runTerminalKite: no
  runProxy      : no
  redis         : "172.16.6.13:6379"
  subscriptionEndpoint   : "http://sandbox.koding.com/-/subscription/check/"
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    authExchange: authExchange
    authAllExchange: authAllExchange
    login       : 'prod-authworker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 2
    watch       : no
  emailConfirmationCheckerWorker :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : no
    cronSchedule         : '0 * * * * *'
    usageLimitInMinutes  : 60
  elasticSearch          :
    host                 : "log0.sjc.koding.com"
    port                 : 9200
    enabled              : no
    queue                : "elasticSearchFeederQueue"
  guestCleanerWorker     :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 2
    watch                : no
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
  sitemapWorker          :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'sitemapworker'
    numberOfWorkers      : 2
    watch                : no
    cronSchedule         : '00 00 00 * * *'
  social        :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : no
    queueName   : socialQueueName
    verbose     : no
    kitePort    : 8765
  log           :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : no
    queueName   : logQueueName
    verbose     : no
    run         : no
    runWorker   : yes
  presence        :
    exchange      : 'services-presence'
  client          :
    version       : version
    watch         : no
    watchDuration : 300
    includesPath  : 'client'
    indexMaster   : "index-master.html"
    index         : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: "http://sandbox.koding.com"
    runtimeOptions:
      kites: require './kites.coffee'
      algolia: #TODO change these credentials
        appId: '8KD9RHY1OA'
        apiKey: 'e4a8ebe91bf848b67c9ac31a6178c64b'
        indexSuffix: '.sandbox'
      osKitePollingMs: 1000 * 60 # 1 min
      userIdleMs: 1000 * 60 * 5 # 5 min
      sessionCookie :
        maxAge      : cookieMaxAge
        secure      : cookieSecure
      environment        : environment
      activityFetchCount : 20
      authExchange       : authExchange
      github         :
        clientId     : "5891e574253e65ddb7ea"
      embedly        :
        apiKey       : embedlyApiKey
      userSitesDomain: 'kd.io'
      logToExternal : no
      logToInternal : no
      resourceName: socialQueueName
      logResourceName: logQueueName
      socialApiUri: 'http://sandbox-social.sj.koding.com:3030/xhr'
      logApiUri: 'https://sandbox-social.sj.koding.com:4030/xhr'
      suppressLogs: no
      version   : version
      mainUri   : "http://sandbox.koding.com"
      broker    :
        servicesEndpoint: "/-/services/broker"
      premiumBroker    :
        servicesEndpoint: "/-/services/broker"
      brokerKite:
        servicesEndpoint: "/-/services/brokerKite"
        brokerExchange: 'brokerKite'
      premiumBrokerKite:
        servicesEndpoint: "/-/services/brokerKite"
        brokerExchange: 'brokerKite'
      apiUri    : 'https://koding.com'
      appsUri   : 'https://rest.kd.io'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
      sourceUri : "http://sandbox.koding.com:1337"
      github    :
        clientId: "f733c52d991ae9642365"
      newkontrol:
        url         : 'https://stage-kontrol.koding.com/kite'
      fileFetchTimeout: 15 * 1000 # seconds
      externalProfiles  :
        github          :
          nicename      : 'GitHub'
          urlLocation   : 'html_url'
        odesk           :
          nicename      : 'oDesk'
          urlLocation   : 'info.profile_url'
        facebook        :
          nicename      : 'Facebook'
          urlLocation   : 'link'
        google          :
          nicename      : 'Google'
        linkedin        :
          nicename      : 'LinkedIn'
        twitter         :
          nicename      : 'Twitter'
        # bitbucket     :
        #   nicename    : 'BitBucket'
      troubleshoot      :
        idleTime        : 1000 * 60 * 60
        externalUrl     : "https://s3.amazonaws.com/koding-ping/healthcheck.json"
      recaptcha         : "6LfFAPcSAAAAAHRGr1Tye4tD-yLz0Ll-EN0yyQ6l"
  mq            :
    host        : '172.16.6.14'
    port        : 5672
    apiAddress  : "172.16.6.14"
    apiPort     : 15672
    login       : 'guest'
    componentUser: "guest"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 20
    vhost       : 'sandbox'
  broker              :
    name              : "broker"
    serviceGenericName: "broker"
    ip                : ""
    port              : 443
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'sandbox.koding.com'
  premiumBroker       :
    name              : "premiumBroker"
    serviceGenericName: "broker"
    ip                : ""
    port              : 443
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'sandbox.koding.com'
  brokerKite          :
    name              : "brokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 453
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'sandbox.koding.com'
  premiumBrokerKite   :
    name              : "premiumBrokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 453
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'sandbox.koding.com'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : "sandbox.koding.com"
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    forcedRecipient : "kodingtestuser@gmail.com"
    maxAge      : 3
  emailSender   :
    run         : yes
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  pidFile       : '/tmp/koding.server.pid'
  newkites      :
    useTLS          : yes
    certFile        : "/etc/ssl/koding/wildcard.sj.koding.com.crt"
    keyFile         : "/etc/ssl/koding/wildcard.sj.koding.com.key"
  newkontrol      :
    port            : 443
    useTLS          : yes
    certFile        : "/opt/koding/certs/koding_com_cert.pem"
    keyFile         : "/opt/koding/certs/koding_com_key.pem"
    publicKeyFile   : "/opt/koding/certs/test_kontrol_rsa_public.pem"
    privateKeyFile  : "/opt/koding/certs/test_kontrol_rsa_private.pem"
  proxyKite       :
    domain        : "127.0.0.1"
    certFile      : "/opt/koding/certs/y_koding_com_cert.pem"
    keyFile       : "/opt/koding/certs/y_koding_com_key.pem"
  etcd            : [ {host: "127.0.0.1", port: 4001} ]
  kontrold        :
    vhost         : "sandbox"
    overview      :
      apiHost     : "172.16.10.34"
      apiPort     : 8081
      port        : 8080
      kodingHost  : "sandbox.koding.com"
      socialHost  : "sandbox-social.koding.com"
    api           :
      port        : 8081
      url         : "http://sandbox-web.sj.koding.com:8081"
    proxy         :
      port        : 8082
      portssl     : 444
      ftpip       : '54.208.3.200'
  recurly         :
    apiKey        : '4a0b7965feb841238eadf94a46ef72ee' # koding-test.recurly.com
    loggedRequests: /^(subscriptions|transactions)/
  embedly       :
    apiKey      : embedlyApiKey
  opsview :
    push  : yes
    host  : 'opsview.in.koding.com'
    bin   : '/usr/local/nagios/bin/send_nsca'
    conf  : '/usr/local/nagios/etc/send_nsca.cfg'
  followFeed    :
    host        : '172.16.6.14'
    port        : 5672
    componentUser: 'guest'
    password    : 'djfjfhgh4455__5'
    vhost       : 'followfeed'
  github        :
    clientId    : "5891e574253e65ddb7ea"
    clientSecret: "9c8e89e9ae5818a2896c01601e430808ad31c84a"
  odesk          :
    key          : "639ec9419bc6500a64a2d5c3c29c2cf8"
    secret       : "549b7635e1e4385e"
    request_url  : "https://www.odesk.com/api/auth/v1/oauth/token/request"
    access_url   : "https://www.odesk.com/api/auth/v1/oauth/token/access"
    secret_url   : "https://www.odesk.com/services/api/auth?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
    redirect_uri : "http://sandbox.koding.com/-/oauth/odesk/callback"
  facebook       :
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirectUri  : "http://sandbox.koding.com/-/oauth/facebook/callback"
  google         :
    client_id    : "1058622748167.apps.googleusercontent.com"
    client_secret: "vlF2m9wue6JEvsrcAaQ-y9wq"
    redirect_uri : "http://sandbox.koding.com/-/oauth/google/callback"
  statsd         :
    use          : true
    ip           : "172.168.2.7"
    port         : 8125
  linkedin       :
    client_id    : "aza9cks1zb3d"
    client_secret: "zIMa5kPYbZjHfOsq"
    redirect_uri : "http://sandbox.koding.com/-/oauth/linkedin/callback"
  twitter        :
    key          : "tvkuPsOd7qzTlFoJORwo6w"
    secret       : "48HXyTkCYy4hvUuRa7t4vvhipv4h04y6Aq0n5wDYmA"
    redirect_uri : "http://sandbox.koding.com/-/oauth/twitter/callback"
    request_url  : "https://twitter.com/oauth/request_token"
    access_url   : "https://twitter.com/oauth/access_token"
    secret_url   : "https://twitter.com/oauth/authenticate?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
  mixpanel       : "113c2731b47a5151f4be44ddd5af0e7a"
  rollbar        : "8108a4c027604f59bac7a8315c205afe"
  slack          :
    token        : "xoxp-2155583316-2155760004-2158149487-a72cf4"
    channel      : "C024LG80K"
  logLevel        :
    oskite        : "info"
    terminal      : "info"
    kontrolproxy  : "debug"
    kontroldaemon : "info"
    vmproxy       : "info"
    graphitefeeder: "info"
    sync          : "info"
    postModifier  : "info"
    router        : "info"
    rerouting     : "info"
    overview      : "info"
    amqputil      : "info"
    rabbitMQ      : "info"
    ldapserver    : "info"
    broker        : "info"
  defaultVMConfigs:
    freeVM        :
      storage     : 3072
      ram         : 1024
      cpu         : 1
  sessionCookie :
    maxAge      : cookieMaxAge
    secure      : cookieSecure
  graphite       :
    use          : true
    host         : "172.168.2.7"
    port         : 2003
  troubleshoot    :
    recipientEmail: "can@koding.com"
  recaptcha       : "6LfFAPcSAAAAAPmec0-3i_hTWE8JhmCu_JWh5h6e"
