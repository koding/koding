fs = require 'fs'
nodePath = require 'path'
deepFreeze = require 'koding-deep-freeze'

version = (fs.readFileSync nodePath.join(__dirname, '../VERSION'), 'utf-8').trim()
projectRoot = nodePath.join __dirname, '..'

socialQueueName = "koding-social-#{version}"

authExchange    = "auth-#{version}"
authAllExchange = "authAll-#{version}"

embedlyApiKey   = '94991069fb354d4e8fdb825e52d4134a'

module.exports =
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "https://koding.com"
  userSitesDomain: 'staging.kd.io'
  containerSubnet: "10.128.2.0/9"
  vmPool        : "vms-staging"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3000
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  sourceServer  :
    enabled     : yes
    port        : 1337
  neo4j         :
    read        : "http://172.16.6.12"
    write       : "http://172.16.6.12"
    port        : 7474
  mongo         : 'dev:k9lc4G1k32nyD72@172.16.6.13:27017/koding'
  mongoReplSet  : null
  runNeo4jFeeder: yes
  runGoBroker   : no
  runKontrol    : no
  runRerouting  : yes
  runUserPresence: yes
  runPersistence: yes
  compileGo     : no
  buildClient   : yes
  runOsKite     : no
  runProxy      : no
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  uploads       :
    enableStreamingUploads: yes
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccountId        : '616271189586'
      awsAccessKeyId      : 'AKIAJO74E23N33AFRGAQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  loggr:
    push: no
    url: "http://post.loggr.net/1/logs/koding/events"
    apiKey: "eb65f620b72044118015d33b4177f805"
  librato :
    push      : no
    email     : ""
    token     : ""
    interval  : 60000
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    authExchange: authExchange
    authAllExchange: authAllExchange
    login       : 'prod-authworker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 2
    watch       : yes
  emailConfirmationCheckerWorker :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'emailConfirmationCheckerWorker'
    numberOfWorkers      : 1
    watch                : yes
    cronSchedule         : '0 * * * * *'
    usageLimitInMinutes  : 60
  guestCleanerWorker     :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'guestcleaner'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 * * * * *'
    usageLimitInMinutes  : 60
  sitemapWorker          :
    enabled              : yes
    login                : 'prod-social'
    queueName            : socialQueueName+'sitemapworker'
    numberOfWorkers      : 2
    watch                : yes
    cronSchedule         : '00 00 00 * * *'
  graphFeederWorker:
    numberOfWorkers: 2
  social        :
    login       : 'prod-social'
    numberOfWorkers: 4
    watch       : yes
    queueName   : socialQueueName
    verbose     : no
  cacheWorker   :
    login       : 'prod-social'
    watch       : yes
    queueName   : socialQueueName+'cache'
    run         : no
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
      precompiledApi: yes
      authExchange: authExchange
      github        :
        clientId    : "5891e574253e65ddb7ea"
      embedly        :
        apiKey       : embedlyApiKey
      userSitesDomain: 'kd.io'
      useNeo4j: yes
      logToExternal : yes
      resourceName: socialQueueName
      suppressLogs: no
      version   : version
      mainUri   : "http://koding.com"
      broker    :
        servicesEndpoint: "/-/services/broker"
        sockJS   : "http://stage-broker-#{version}.sj.koding.com/subscribe"
      apiUri    : 'https://www.koding.com'
      appsUri   : 'https://koding-apps.s3.amazonaws.com'
      uploadsUri: 'https://koding-uploads.s3.amazonaws.com'
      sourceUri : "http://stage-webserver-#{version}.sj.koding.com:1337"
      github    :
        clientId: "f733c52d991ae9642365"
      newkontrol:
        host    : '127.0.0.1'
        port    : 80
  mq            :
    host        : '172.16.6.14'
    port        : 5672
    apiAddress  : "172.16.6.14"
    apiPort     : 15672
    login       : 'guest'
    componentUser: "guest"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 20
    vhost       : 'new'
  broker        :
    ip          : ""
    port        : 80
    certFile    : ""
    keyFile     : ""
    webProtocol : 'http:'
    webHostname : "stage-broker-#{version}.sj.koding.com"
    webPort     : null
    authExchange: authExchange
    authAllExchange: authAllExchange
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
    forcedRecipient : 'noreply@koding.com'
  emailSender   :
    run         : no
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  pidFile       : '/tmp/koding.server.pid'
  haproxy:
    webPort     : 3020
  newkontrol      :
    host          : "127.0.0.1"
    port          : 80
  kontrold        :
    vhost         : "/"
    overview      :
      apiHost     : "172.16.6.16"
      apiPort     : 80
      port        : 8080
      switchHost  : "y.koding.com"
    api           :
      port        : 80
    proxy         :
      port        : 80
      portssl     : 443
      ftpip       : '54.208.3.200'
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a' # koding.recurly.com
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
    redirect_uri : "http://koding.com/-/oauth/odesk/callback"
  facebook       :
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirectUri  : "https://koding.com/-/oauth/facebook/callback"
  google         :
    client_id    : "1058622748167.apps.googleusercontent.com"
    client_secret: "vlF2m9wue6JEvsrcAaQ-y9wq"
    redirect_uri : "http://localhost:3020/-/oauth/google/callback"
  statsd         :
    use          : true
    ip           : "172.168.2.7"
    port         : 8125
  linkedin       :
    client_id    : "aza9cks1zb3d"
    client_secret: "zIMa5kPYbZjHfOsq"
    redirect_uri : "http://koding.com/-/oauth/linkedin/callback"
  twitter        :
    key          : "tvkuPsOd7qzTlFoJORwo6w"
    secret       : "48HXyTkCYy4hvUuRa7t4vvhipv4h04y6Aq0n5wDYmA"
    redirect_uri : "http://koding.com/-/oauth/twitter/callback"
    request_url  : "https://twitter.com/oauth/request_token"
    access_url   : "https://twitter.com/oauth/access_token"
    secret_url   : "https://twitter.com/oauth/authenticate?oauth_token="
    version      : "1.0"
    signature    : "HMAC-SHA1"
