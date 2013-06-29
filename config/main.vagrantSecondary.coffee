fs              = require 'fs'
nodePath        = require 'path'
deepFreeze      = require 'koding-deep-freeze'

version         = "0.0.1"
mongo           = 'dev:k9lc4G1k32nyD72@10.0.2.2:27017/koding'
projectRoot     = nodePath.join __dirname, '..'
socialQueueName = "koding-social-vagrant"

module.exports =
  aws           :
    key         : 'AKIAJSUVKX6PD254UGAA'
    secret      : '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'
  uri           :
    address     : "http://localhost:3020"
  userSitesDomain: 'localhost'
  containerSubnet: "10.128.2.0/9"
  projectRoot   : projectRoot
  version       : version
  webserver     :
    login       : 'prod-webserver'
    port        : 3020
    clusterSize : 1
    queueName   : socialQueueName+'web'
    watch       : yes
  sourceServer  :
    enabled     : yes
    port        : 1337
  neo4j         :
    read        : "http://localhost"
    write       : "http://localhost"
    port        : 7474
  mongo         : mongo
  runNeo4jFeeder: yes
  runGoBroker   : yes
  runRerouting  : yes
  compileGo     : yes
  buildClient   : yes
  runOsKite     : yes
  runProxy      : no
  misc          :
    claimGlobalNamesForUsers: no
    updateAllSlugs : no
    debugConnectionErrors: yes
  uploads       :
    enableStreamingUploads: no
    distribution: 'https://d2mehr5c6bceom.cloudfront.net'
    s3          :
      awsAccountId        : '616271189586'
      awsAccessKeyId      : 'AKIAJO74E23N33AFRGAQ'
      awsSecretAccessKey  : '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'
      bucket              : 'koding-uploads'
  # loadBalancer  :
  #   port        : 3000
  #   heartbeat   : 5000
    # httpRedirect:
    #   port      : 80 # don't forget port 80 requires sudo
  bitly :
    username  : "kodingen"
    apiKey    : "R_677549f555489f455f7ff77496446ffa"
  authWorker    :
    login       : 'prod-auth-worker'
    queueName   : socialQueueName+'auth'
    numberOfWorkers: 1
    watch       : yes
  graphFeederWorker:
    numberOfWorkers: 2
  social        :
    login       : 'prod-social'
    numberOfWorkers: 1
    watch       : yes
    queueName   : socialQueueName
  cacheWorker   :
    login       : 'prod-social'
    watch       : yes
    queueName   : socialQueueName+'cache'
    run         : no
  presence      :
    exchange    : 'services-presence'
  client        :
    version     : version
    watch       : yes
    watchDuration : 300
    includesPath: 'client'
    websitePath : 'website'
    js          : "js/kd.#{version}.js"
    css         : "css/kd.#{version}.css"
    indexMaster : "index-master.html"
    index       : "default.html"
    useStaticFileServer: no
    staticFilesBaseUrl: 'http://localhost:3020'
    runtimeOptions:
      userSitesDomain: 'localhost'
      useNeo4j: no
      logToExternal: no  # rollbar, mixpanel etc.
      resourceName: socialQueueName
      suppressLogs: no
      broker    :
        sockJS  : 'http://localhost:8008/subscribe'
      apiUri    : 'https://dev-api.koding.com'
      # Is this correct?
      version   : version
      mainUri   : 'http://localhost:3020'
      appsUri   : 'https://koding-apps.s3.amazonaws.com'
      sourceUri : 'http://localhost:1337'
  mq            :
    host        : '10.0.2.2'
    port        : 5672
    apiAddress  : "10.0.2.2"
    apiPort     : 15672
    login       : 'PROD-k5it50s4676pO9O'
    componentUser: "PROD-k5it50s4676pO9O"
    password    : 'djfjfhgh4455__5'
    heartbeat   : 10
    vhost       : '/'
  broker        :
    ip          : ""
    port        : 8008
    certFile    : ""
    keyFile     : ""
  kites:
    disconnectTimeout: 3e3
    vhost       : 'kite'
  email         :
    host        : 'localhost'
    protocol    : 'http:'
    defaultFromAddress: 'hello@koding.com'
  emailWorker   :
    cronInstant : '*/10 * * * * *'
    cronDaily   : '0 10 0 * * *'
    run         : no
    defaultRecepient : undefined
  emailSender   :
    run         : no
  guests        :
    # define this to limit the number of guset accounts
    # to be cleaned up per collection cycle.
    poolSize        : 1e4
    batchSize       : undefined
    cleanupCron     : '*/10 * * * * *'
  pidFile       : '/tmp/koding.server.pid'
  loggr:
    push: no
    url: ""
    apiKey: ""
  librato:
    push: no
    email: ""
    token: ""
    interval: 60000
  haproxy:
    webPort     : 3020
  # crypto :
  #   encrypt: (str,key=Math.floor(Date.now()/1000/60))->
  #     crypto = require "crypto"
  #     str = str+""
  #     key = key+""
  #     cipher = crypto.createCipher('aes-256-cbc',""+key)
  #     cipher.update(str,'utf-8')
  #     a = cipher.final('hex')
  #     return a
  #   decrypt: (str,key=Math.floor(Date.now()/1000/60))->
  #     crypto = require "crypto"
  #     str = str+""
  #     key = key+""
  #     decipher = crypto.createDecipher('aes-256-cbc',""+key)
  #     decipher.update(str,'hex')
  #     b = decipher.final('utf-8')
  #     return b
  recurly       :
    apiKey      : '0cb2777651034e6889fb0d091126481a'
  opsview       :
    push        : no
    host        : ''
  followFeed    :
    host        : 'localhost'
    port        : 5672
    componentUser: 'guest'
    password    : 'guest'
    vhost       : 'followfeed'


