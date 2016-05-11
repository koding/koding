module.exports = (options, credentials) ->

  email =
    host: "#{options.customDomain.public_}"
    defaultFromMail: options.defaultEmail
    defaultFromName: 'Koding'
    forcedRecipientEmail: null
    forcedRecipientUsername: null

  githubapi      =
    debug       : options.debugGithubAPI
    timeout     : 5000
    userAgent   : "Koding-Bridge-#{options.configName}"

  regions =
    kodingme: "#{options.configName}"
    vagrant: "vagrant"
    sj: "sj"
    aws: "aws"
    premium: "vagrant"

  paymentwebhook =
    port: "6600"
    debug: false
    customersKey: credentials.paymentwebhook.customersKey
    secretKey: credentials.paymentwebhook.secretKey

  broker =
    name: "broker"
    serviceGenericName: "broker"
    ip: ""
    webProtocol: options.protocol
    host: "#{options.customDomain.public}"
    port: 8008
    certFile: ""
    keyFile: ""
    authExchange: "auth"
    authAllExchange: "authAll"
    failoverUri: "#{options.customDomain.public}"

  tunnelserver =
    port           : 80
    basevirtualhost: "koding.me"
    hostedzone     : "koding.me"

  algoliaSecret =
    appId: credentials.algolia.appId
    indexSuffix: options.algoliaIndexSuffix
    apiSecretKey: credentials.algolia.apiSecretKey
    apiSearchOnlyKey: credentials.algolia.apiSearchOnlyKey

  gatekeeper =
    host: "localhost"
    port: "7200"
    pubnub: credentials.pubnub

  integration =
    host: "localhost"
    port: "7300"
    url: "#{options.customDomain.public}/api/integration"

  webhookMiddleware =
    host: "localhost"
    port: "7350"
    url: "#{options.customDomain.public}/api/webhook"

  recaptcha =
    enabled: options.recaptchaEnabled
    secret: credentials.recaptcha.secret
    url: "https://www.google.com/recaptcha/api/siteverify"

  kontrol =
    url: "#{options.customDomain.public}/kontrol/kite"
    port: 3000
    useTLS: no
    certFile: ""
    keyFile: ""
    publicKeyFile: credentials.kontrol.publicKeyFile
    privateKeyFile: credentials.kontrol.privateKeyFile

  kloudPort = 5500
  kloud =
    port: kloudPort
    userPrivateKeyFile: credentials.kloud.userPrivateKeyFile
    userPublicKeyfile: credentials.kloud.userPublicKeyfile
    privateKeyFile: credentials.kloud.privateKeyFile
    publicKeyFile: credentials.kloud.publicKeyFile
    secretKey: credentials.kloud.secretKey
    kontrolUrl: kontrol.url
    registerUrl: "#{options.customDomain.public}/kloud/kite"
    address: "http://localhost:#{kloudPort}/kite"
    tunnelUrl: "#{options.tunnelUrl}"
    klientUrl: "https://s3.amazonaws.com/koding-klient/development/latest/klient.deb"
  vmwatcher =
    port: "6400"
    awsKey: credentials.awsKeys.vm_vmwatcher.accessKeyId
    awsSecret: credentials.awsKeys.vm_vmwatcher.secretAccessKey
    kloudSecretKey: kloud.secretKey
    kloudAddr: kloud.address
    connectToKlient: options.vmwatcherConnectToKlient
    debug: false,
    mongo: credentials.mongo
    redis: credentials.redis.url
    secretKey: credentials.vmwatcher.secretKey

  hubspotPageURL      = "http://www.koding.com"

  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go
  socialapi =
    environment            : options.environment
    region                 : options.region
    hostname               : options.host
    protocol               : options.protocol
    disabledFeatures       : options.disabledFeatures

    stripe                 : credentials.stripe
    paypal                 : credentials.paypal
    github                 : credentials.github
    janitor                : credentials.janitor
    postgres               : credentials.postgres
    mq                     : credentials.rabbitmq
    redis                  : credentials.redis
    mongo                  : credentials.mongo
    googleapiServiceAccount: credentials.googleapiServiceAccount
    slack                  : credentials.slack
    sneakerS3              : credentials.sneakerS3
    mailgun                : credentials.mailgun
    segment                : credentials.segment

    algolia                : algoliaSecret
    gatekeeper             : gatekeeper
    integration            : integration
    webhookMiddleware      : webhookMiddleware
    paymentwebhook         : paymentwebhook
    customDomain           : options.customDomain
    email                  : email

    sitemap                : { redisDB: 0, updateInterval: "1m" }
    limits                 : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: 30 }
    kloud                  : { secretKey: kloud.secretKey, address: kloud.address }
    geoipdbpath            : "#{options.projectRoot}/go/data/geoipdb"
    eventExchangeName      : "BrokerMessageBus"
    proxyUrl               : "#{options.customDomain.local}/api/social"
    port                   : "7000"
    configFilePath         : "#{options.projectRoot}/go/src/socialapi/config/#{options.configName}.toml"
    disableCaching         : no
    debug                  : no

  KONFIG =
    configName                    : options.configName
    environment                   : options.environment
    ebEnvName                     : options.ebEnvName
    runGoWatcher                  : options.runGoWatcher
    region                        : options.region
    hostname                      : options.host
    protocol                      : options.protocol
    publicPort                    : options.publicPort
    publicHostname                : options.publicHostname
    version                       : options.version
    projectRoot                   : options.projectRoot
    sendEventsToSegment           : options.sendEventsToSegment
    userSitesDomain               : options.userSitesDomain
    disabledFeatures              : options.disabledFeatures
    autoConfirmAccounts           : options.autoConfirmAccounts
    domains                       : options.domains

    kiteHome                      : credentials.kiteHome
    redis                         : credentials.redis.url
    monitoringRedis               : credentials.monitoringRedis.url
    mongo                         : credentials.mongo
    mq                            : credentials.rabbitmq
    terraformer                   : credentials.terraformer
    recurly                       : credentials.recurly
    google                        : credentials.google
    twitter                       : credentials.twitter
    linkedin                      : credentials.linkedin
    datadog                       : credentials.datadog
    github                        : credentials.github
    odesk                         : credentials.odesk
    facebook                      : credentials.facebook
    slack                         : credentials.slack
    sneakerS3                     : credentials.sneakerS3
    embedly                       : credentials.embedly
    integration                   : credentials.integration
    googleapiServiceAccount       : credentials.googleapiServiceAccount
    siftScience                   : credentials.siftScience
    jwt                           : credentials.jwt
    papertrail                    : credentials.papertrail
    mailgun                       : credentials.mailgun
    helpscout                     : credentials.helpscout
    awsKeys                       : credentials.awsKeys
    segment                       : credentials.segment

    paymentwebhook                : paymentwebhook
    regions                       : regions
    broker                        : broker
    tunnelserver                  : tunnelserver
    hubspotPageURL                : hubspotPageURL
    socialapi                     : socialapi
    githubapi                     : githubapi
    email                         : email
    kloud                         : kloud
    kontrol                       : kontrol
    gatekeeper                    : gatekeeper
    integration                   : integration
    recaptcha                     : recaptcha
    vmwatcher                     : vmwatcher
    uri                           : { address: options.customDomain.public }
    misc                          : { claimGlobalNamesForUsers: no , debugConnectionErrors: yes, updateAllSlugs: false }
    # TODO: average request count per hour for a user should be measured and a reasonable limit should be set
    nodejsRateLimiter             : { enabled: no, guestRules: [{ interval: 3600, limit: 5000 }], userRules: [{ interval: 3600, limit: 10000 }] } # limit: request limit per rate limit window, interval: rate limit window duration in seconds
    webserver                     : { port: 8080, useCacheHeader: no , kitePort: 8860 }
    authWorker                    : { login: credentials.rabbitmq.login, queueName: options.socialQueueName + 'auth', authExchange: "auth", authAllExchange: "authAll", port : 9530 }
    social                        : { port: 3030, login: "#{credentials.rabbitmq.login}", queueName: options.socialQueueName, kitePort: 8760 }
    boxproxy                      : { port: parseInt(options.publicPort, 10) }
    sourcemaps                    : { port: 3526 }
    rerouting                     : { port: 9500 }
    gowebserver                   : { port: 6500 }
    gatheringestor                : { port: 6800 }
    sessionCookie                 : { maxAge: 1000 * 60 * 60 * 24 * 14, secure: options.secureCookie }
    troubleshoot                  : { recipientEmail: "can@koding.com" }
    contentRotatorUrl             : 'http://koding.github.io'
    collaboration                 : { timeout: 1 * 60 * 1000 }
    client                        : { watch: yes, version: options.version, includesPath:'client' , indexMaster: "index-master.html" , index: "default.html" , useStaticFileServer: no , staticFilesBaseUrl: "#{options.customDomain.public}:#{options.customDomain.port}" }
    contentRotatorUrl              : 'http://koding.github.io'

  return KONFIG
