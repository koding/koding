fs = require 'fs'
nodePath = require 'path'
deepFreeze = require 'koding-deep-freeze'

version = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()
projectRoot = nodePath.join __dirname, '..'

mongo        = 'dev:k9lc4G1k32nyD72@172.16.3.9:27017/koding'
mongoKontrol = 'dev:k9lc4G1k32nyD72@172.16.3.9:27017/kontrol'

mongoReplSet = 'mongodb://dev:k9lc4G1k32nyD72@172.16.3.9,172.16.3.10,172.16.3.15/koding?replicaSet=koodingrs0&readPreference=primaryPreferred'

socialQueueName = "koding-social-#{version}"
logQueueName    = socialQueueName+'log'

authExchange    = "auth-#{version}"
authAllExchange = "authAll-#{version}"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

environment     = "production"
regions         =
  vagrant       : "vagrant"
  sj            : "sj"
  aws           : "aws"
  premium       : "premium-sj"

cookieMaxAge = 1000 * 60 * 60 * 24 * 14 # two weeks
cookieSecure = yes

module.exports =
  environment   : environment
  regions       : regions
  version       : version
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "https://koding.com"
  userSitesDomain: 'kd.io'
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms"
  projectRoot   : projectRoot
  webserver     :
    useCacheHeader: yes
    login       : 'prod-webserver'
    port        : 3000
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : no
  socialApiUrl  : "http://localhost:7000"
  sourceServer  :
    enabled     : no
    port        : 1337
  neo4j         :
    read        : "http://172.16.3.16"
    write       : "http://172.16.3.16"
    port        : 7474
  mongo         : mongo
  mongoKontrol  : mongoKontrol
  mongoReplSet  : mongoReplSet
  mongoMinWrites: 3
  runNeo4jFeeder: yes
  runGoBroker   : no
  runGoBrokerKite : no
  runPremiumBrokerKite : no
  runPremiumBroker : no
  runKontrol    : yes
  runRerouting  : yes
  runPersistence: yes
  compileGo     : no
  buildClient   : yes
  runOsKite     : no
  runTerminalKite: no
  runProxy      : no
  redis         : "172.16.3.13:6379"
  subscriptionEndpoint   : "https://koding.com/-/subscription/check/"
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
    enabled              : no
    login                : 'prod-social'
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : no
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
  elasticSearch          :
    host                 : "log0.sjc.koding.com"
    port                 : 9200
    enabled              : no
    queue                : "elasticSearchFeederQueue"
  guestCleanerWorker     :
    enabled              : no # for production, workers are running as a service
    login                : 'prod-social'
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 1
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
  topicModifier          :
    cronSchedule         : '0 */5 * * * *'
  graphFeederWorker:
    numberOfWorkers: 4
  social        :
    login       : 'prod-social'
    numberOfWorkers: 7
    watch       : no
    queueName   : socialQueueName
    verbose     : no
    kitePort    : 8765
  log           :
    login       : 'prod-social'
    numberOfWorkers: 2
    watch       : yes
    queueName   : logQueueName
    verbose     : no
    run         : yes
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
    staticFilesBaseUrl: "https://koding.com"
    runtimeOptions:
      kites: require './kites.coffee'
      osKitePollingMs: 1000 * 60 # 1 min
      userIdleMs: 1000 * 60 * 5 # 5 min
      sessionCookie :
        maxAge      : cookieMaxAge
        secure      : cookieSecure
      environment        : environment
      activityFetchCount : 20
      authExchange       : authExchange
      github        :
        clientId    : "5891e574253e65ddb7ea"
      embedly        :
        apiKey       : embedlyApiKey
      userSitesDomain: 'kd.io'
      useNeo4j: yes
      logToExternal : yes
      logToInternal : yes
      resourceName: socialQueueName
      logResourceName: logQueueName
      socialApiUri: 'https://social.koding.com/xhr'
      logApiUri   : 'https://log.koding.com/xhr'
      suppressLogs: yes
      version   : version
      mainUri   : "https://koding.com"
      broker    :
        servicesEndpoint: "/-/services/broker"
      premiumBroker    :
        servicesEndpoint: "/-/services/premiumBroker"
      brokerKite:
        servicesEndpoint: "/-/services/brokerKite"
        brokerExchange: 'brokerKite'
      premiumBrokerKite:
        servicesEndpoint: "/-/services/premiumBrokerKite"
        brokerExchange: 'premiumBrokerKite'
      apiUri    : 'https://koding.com'
      appsUri   : 'https://apps.koding.com'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
      sourceUri : "http://webserver-#{version}a.sj.koding.com:1337"
      newkontrol:
        url         : 'https://kontrol.koding.com/kite'
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
      hangouts          :
        projectId       : "134407769088"
  mq            :
    host        : '172.16.3.4'
    port        : 5672
    apiAddress  : "172.16.3.4"
    apiPort     : 15672
    login       : 'guest'
    componentUser: "guest"
    password    : 'Xah8ibeekelah'
    heartbeat   : 20
    vhost       : 'new'
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
    failoverUri       : 'broker.koding.com'
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
    failoverUri       : 'premiumbroker.koding.com'
  brokerKite          :
    name              : "brokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 443
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'brokerkite.koding.com'
  premiumBrokerKite   :
    name              : "premiumBrokerKite"
    serviceGenericName: "brokerKite"
    ip                : ""
    port              : 443
    certFile          : "/opt/ssl_certs/wildcard.koding.com.cert"
    keyFile           : "/opt/ssl_certs/wildcard.koding.com.key"
    webProtocol       : 'https:'
    authExchange      : authExchange
    authAllExchange   : authAllExchange
    failoverUri       : 'premiumbrokerkite.koding.com'
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : "koding.com"
    protocol    : 'https:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    forcedRecipient : undefined
    maxAge      : 3
  emailSender   :
    run         : no
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
    publicKeyFile   : "/opt/koding/certs/prod_kontrol_rsa_public.pem"
    privateKeyFile  : "/opt/koding/certs/prod_kontrol_rsa_private.pem"
  proxyKite       :
    domain        : "x.koding.com"
    certFile      : "/opt/koding/go/src/koding/kontrol/kontrolproxy/files/10.0.5.102_cert.pem"
    keyFile       : "/opt/koding/go/src/koding/kontrol/kontrolproxy/files/10.0.5.102_key.pem"
  etcd            : [ {host: "127.0.0.1", port: 4001} ]
  kontrold        :
    vhost         : "/"
    overview      :
      apiHost     : "172.16.3.11"
      apiPort     : 80
      port        : 8080
      kodingHost  : "koding.com"
      socialHost  : "social.koding.com"
    api           :
      port        : 80
      url         : "http://kontrol0.sj.koding.com"
    proxy         :
      port        : 80
      portssl     : 443
      ftpip       : '54.208.3.200'
  recurly         :
    apiKey        : '0cb2777651034e6889fb0d091126481a' # koding.recurly.com
    loggedRequests: /^(subscriptions|transactions)/
  embedly       :
    apiKey      : embedlyApiKey
  opsview	:
    push	: yes
    host	: 'opsview.in.koding.com'
    bin   : '/usr/local/nagios/bin/send_nsca'
    conf  : '/usr/local/nagios/etc/send_nsca.cfg'
  followFeed    :
    host        : '172.16.3.4'
    port        : 5672
    componentUser: 'guest'
    password    : 'Xah8ibeekelah'
    vhost       : 'followfeed'
  github        :
    clientId    : "5891e574253e65ddb7ea"
    clientSecret: "9c8e89e9ae5818a2896c01601e430808ad31c84a"
  odesk          :
    key          : "9ed4e3e791c61a1282c703a42f6e10b7"
    secret       : "1df959f971cb437c"
    request_url  : "https://www.odesk.com/api/auth/v1/oauth/token/request"
    access_url   : "https://www.odesk.com/api/auth/v1/oauth/token/access"
    secret_url   : "https://www.odesk.com/services/api/auth?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
    redirect_uri : "https://koding.com/-/oauth/odesk/callback"
  facebook       :
    clientId     : "434245153353814"
    clientSecret : "84b024e0d627d5e80ede59150a2b251e"
    redirectUri  : "https://koding.com/-/oauth/facebook/callback"
  google         :
    client_id    : "134407769088.apps.googleusercontent.com"
    client_secret: "6Is_WwxB19tuY2xkZNbnAU-t"
    redirect_uri : "https://koding.com/-/oauth/google/callback"
  statsd         :
    use          : true
    ip           : "172.168.2.7"
    port         : 8125
  graphite       :
    use          : true
    host         : "172.168.2.7"
    port         : 2003
  linkedin       :
    client_id    : "aza9cks1zb3d"
    client_secret: "zIMa5kPYbZjHfOsq"
    redirect_uri : "https://koding.com/-/oauth/linkedin/callback"
  twitter        :
    key          : "tvkuPsOd7qzTlFoJORwo6w"
    secret       : "48HXyTkCYy4hvUuRa7t4vvhipv4h04y6Aq0n5wDYmA"
    redirect_uri : "https://koding.com/-/oauth/twitter/callback"
    request_url  : "https://twitter.com/oauth/request_token"
    access_url   : "https://twitter.com/oauth/access_token"
    secret_url   : "https://twitter.com/oauth/authenticate?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
  mixpanel       : "d35a8d0b14e284f32ab5380590c6848a"
  rollbar        : "cc4daee549e3405e9e139d34c5bce45b"
  slack          :
    token        : "xoxp-2155583316-2155760004-2158149487-a72cf4"
    channel      : "C024LG80K"
  logLevel        :
    neo4jfeeder   : "info"
    oskite        : "info"
    terminal      : "info"
    kontrolproxy  : "info"
    kontroldaemon : "info"
    userpresence  : "info"
    vmproxy       : "info"
    graphitefeeder: "info"
    sync          : "info"
    topicModifier : "info"
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
  troubleshoot    :
    recipientEmail: "support@koding.com"
  recaptcha       : "6LfFAPcSAAAAAPmec0-3i_hTWE8JhmCu_JWh5h6e"
