module.exports = (options, credentials) ->

  email =
    host: "#{options.customDomain.public_}"
    defaultFromMail: options.defaultEmail
    defaultFromName: 'Koding'
    forcedRecipientEmail: null
    forcedRecipientUsername: null

  githubapi =
    debug: options.debugGithubAPI
    timeout: 5000
    userAgent: "Koding-Bridge-#{options.configName}"

  gitlab =
    host: options.gitlabHost or credentials.gitlab.host
    port: options.gitlabPort or credentials.gitlab.port or 3000
    applicationId: options.gitlabAppId or credentials.gitlab.applicationId
    applicationSecret: options.gitlabAppSecret or credentials.gitlab.applicationSecret
    team: credentials.gitlab.team
    redirectUri: "http://#{credentials.gitlab.team}.#{options.host}/-/oauth/gitlab/callback"
    systemHookToken: options.gitlabToken or credentials.gitlab.systemHookToken
    hooksEnabled: options.gitlabHost? or credentials.gitlab?.host? or credentials.gitlab?.hooksEnabled

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

  tunnelproxymanager =
    ebEnvName: options.ebEnvName

    accessKeyId:     credentials.awsKeys.worker_tunnelproxymanager.accessKeyId
    secretAccessKey: credentials.awsKeys.worker_tunnelproxymanager.secretAccessKey

    route53AccessKeyId: credentials.awsKeys.worker_tunnelproxymanager_route53.accessKeyId
    route53SecretAccessKey: credentials.awsKeys.worker_tunnelproxymanager_route53.secretAccessKey

    hostedZone:
        name: options.tunnelHostedZoneName
        callerReference: options.tunnelHostedZoneCallerRef

  tunnelserver =
    port: 80

    region     : options.region
    environment: options.environment

    accessKey: credentials.awsKeys.worker_tunnelproxymanager.accessKeyId
    secretKey: credentials.awsKeys.worker_tunnelproxymanager.secretAccessKey

    hostedzone      : options.tunnelserverHostedZone
    basevirtualhost : options.tunnelserverBasevirtualHost

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
    port: 3000
    storage: 'postgres'
    postgres: credentials.kontrolPostgres

    mongoUrl: credentials.mongo

    region: options.region
    environment: options.environment

    url: "#{options.customDomain.public}/kontrol/kite"

    useTLS: no
    tlsCertFile: ""
    tlsKeyFile: ""

    publicKey: credentials.kontrol.publicKey
    privateKey: credentials.kontrol.privateKey

  socialApiProxyUrl = "#{options.customDomain.local}/api/social"
  vmwatcherPort = '6400'

  kloud =
    port: kloudPort = 5500
    kloudSecretKey: credentials.kloud.secretKey

    mongoUrl: credentials.mongo

    region: options.region
    environment: options.environment
    prodMode: options.configName is 'prod'
    hostedZone: options.userSitesDomain

    publicKey: credentials.kloud.publicKey
    privateKey: credentials.kloud.privateKey

    userPublicKey: credentials.kloud.userPublicKey
    userPrivateKey: credentials.kloud.userPrivateKey

    keygenAccessKey: credentials.kloud.keygenAccessKey
    keygenSecretKey: credentials.kloud.keygenSecretKey
    keygenBucket: credentials.kloud.keygenBucket

    address: "http://localhost:#{kloudPort}/kite"

    kontrolUrl: kontrol.url
    registerUrl: "#{options.customDomain.public}/kloud/kite"
    tunnelUrl: "#{options.tunnelUrl}"
    klientUrl: "https://s3.amazonaws.com/koding-klient/development/latest/klient.deb"

    planEndpoint: "#{socialApiProxyUrl}/payments/subscriptions"
    credentialEndPoint: "#{socialApiProxyUrl}/credential"
    networkUsageEndpoint: "http://localhost:#{vmwatcherPort}"

    janitorSecretKey: credentials.janitor.secretKey
    vmWatcherSecretKey: credentials.vmwatcher.secretKey
    paymentWebHookSecretKey: credentials.paymentwebhook.secretKey
    terraformerSecretKey: credentials.terraformer.secretKey

    awsAccessKeyId: credentials.awsKeys.vm_kloud.accessKeyId
    awsSecretAccessKey: credentials.awsKeys.vm_kloud.secretAccessKey

  vmwatcher =
    port: vmwatcherPort
    awsKey: credentials.awsKeys.vm_vmwatcher.accessKeyId
    awsSecret: credentials.awsKeys.vm_vmwatcher.secretAccessKey
    kloudSecretKey: kloud.kloudSecretKey
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
    gitlab                 : gitlab
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
    dummyAdmins            : credentials.dummyAdmins
    druid                  : credentials.druid
    clearbit               : credentials.clearbit

    algolia                : algoliaSecret
    gatekeeper             : gatekeeper
    integration            : integration
    webhookMiddleware      : webhookMiddleware
    paymentwebhook         : paymentwebhook
    customDomain           : options.customDomain
    email                  : email

    sitemap                : { redisDB: 0, updateInterval: "1m" }
    limits                 : { messageBodyMinLen: 1, postThrottleDuration: "15s", postThrottleCount: 30 }
    kloud                  : { secretKey: kloud.kloudSecretKey, address: kloud.address }
    geoipdbpath            : "$KONFIG_PROJECTROOT/go/data/geoipdb"
    eventExchangeName      : "BrokerMessageBus"
    proxyUrl               : socialApiProxyUrl
    port                   : "7000"
    configFilePath         : "$KONFIG_PROJECTROOT/go/src/socialapi/config/#{options.configName}.toml"
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
    clientUploadS3BucketName      : options.clientUploadS3BucketName

    kiteHome                      : credentials.kiteHome
    redis                         : credentials.redis
    monitoringRedis               : credentials.monitoringRedis
    mongo                         : credentials.mongo
    postgres                      : credentials.postgres
    mq                            : credentials.rabbitmq
    terraformer                   : credentials.terraformer
    recurly                       : credentials.recurly
    google                        : credentials.google
    twitter                       : credentials.twitter
    linkedin                      : credentials.linkedin
    datadog                       : credentials.datadog
    github                        : credentials.github
    gitlab                        : gitlab
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
    dummyAdmins                   : credentials.dummyAdmins
    druid                         : credentials.druid
    clearbit                      : credentials.clearbit

    paymentwebhook                : paymentwebhook
    regions                       : regions
    broker                        : broker
    tunnelproxymanager            : tunnelproxymanager
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
    webserver                     : { port: 8080, useCacheHeader: no }
    authWorker                    : { login: credentials.rabbitmq.login, queueName: options.socialQueueName + 'auth', authExchange: "auth", authAllExchange: "authAll", port : 9530 }
    social                        : { port: 3030, login: "#{credentials.rabbitmq.login}", queueName: options.socialQueueName, kitePort: 8760, kiteKey: "#{credentials.kiteHome}/kite.key" }
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
