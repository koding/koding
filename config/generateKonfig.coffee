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
    vagrant: 'vagrant'
    sj: 'sj'
    aws: 'aws'
    premium: 'vagrant'

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

  gatekeeper =
    host: 'localhost'
    port: '7200'
    pubnub: credentials.pubnub

  recaptcha =
    enabled: options.recaptchaEnabled
    secret: credentials.recaptcha.secret
    invisible_secret: credentials.recaptcha.invisible_secret
    url: 'https://www.google.com/recaptcha/api/siteverify'

  kontrol =
    port: 3000
    storage: 'postgres'
    postgres: credentials.kontrolPostgres

    mongoUrl: credentials.mongo

    region: options.region
    environment: options.environment

    url: "#{options.customDomain.public}/kontrol/kite"

    useTLS: no
    tlsCertFile: ''
    tlsKeyFile: ''

    publicKey: credentials.kontrol.publicKey
    privateKey: credentials.kontrol.privateKey

  kontrol.postgres.url = do (postgres = kontrol.postgres) ->
    { username, password, host, port, dbname } = postgres
    "postgres://#{username}:#{password}@#{host}:#{port}/#{dbname}"

  socialApiProxyUrl = "#{options.customDomain.local}/api/social"

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
    noSneaker: false

    kontrolUrl: kontrol.url
    kodingUrl:  "#{options.customDomain.public}"
    registerUrl: "#{options.customDomain.public}/kloud/kite"
    tunnelUrl: "#{options.tunnelUrl}"
    klientUrl: 'https://s3.amazonaws.com/koding-klient/development/latest/klient.deb'
    kiteMetricsPublishUrl: "#{socialApiProxyUrl}/countly/publishkite"
    terraformerSecretKey: credentials.terraformer.secretKey

  marketingPagesURL = 'http://www.koding.com'

  # configuration for socialapi, order will be the same with
  # ./go/src/socialapi/config/configtypes.go
  socialapi =
    environment            : options.environment
    region                 : options.region
    hostname               : options.host
    protocol               : options.protocol
    disabledFeatures       : options.disabledFeatures

    stripe                 : credentials.stripe
    github                 : credentials.github
    postgres               : credentials.postgres
    mq                     : credentials.rabbitmq
    mongo                  : credentials.mongo
    googleapiServiceAccount: credentials.googleapiServiceAccount
    slack                  : credentials.slack
    sneakerS3              : credentials.sneakerS3
    mailgun                : credentials.mailgun
    segment                : credentials.segment
    dummyAdmins            : credentials.dummyAdmins
    countly                : credentials.countly
    clearbit               : credentials.clearbit

    gatekeeper             : gatekeeper
    customDomain           : options.customDomain
    email                  : email

    limits                 : { messageBodyMinLen: 1, postThrottleDuration: '15s', postThrottleCount: 30 }
    kloud                  : { secretKey: kloud.kloudSecretKey, address: kloud.address }
    geoipdbpath            : '$KONFIG_PROJECTROOT/go/data/geoipdb'
    eventExchangeName      : 'BrokerMessageBus'
    proxyUrl               : socialApiProxyUrl
    port                   : '7000'
    configFilePath         : "$KONFIG_PROJECTROOT/go/src/socialapi/config/#{options.configName}.toml"
    disableCaching         : no
    debug                  : no

  socialapi.postgres.url = do (postgres = socialapi.postgres) ->
    { username, password, host, port, dbname } = postgres
    "postgres://#{username}:#{password}@#{host}:#{port}/#{dbname}"

  # configuration for Go's back-end part of Koding. Configuration structure is
  # defined in ./go/src/koding/kites/config/config.go
  goKoding =
    environment        : options.environment
    buckets            :
      publicLogs       :
        name           : options.publicLogsS3BucketName
        region         : 'us-east-1'
    endpoints          :
      ip               :
        public         : "https://#{options.proxySubdomain}.koding.com/-/ip"
      ipCheck          :
        public         : "https://#{options.proxySubdomain}.koding.com/-/ipcheck"
      kdLatest         :
        public         : "https://koding-kd.s3.amazonaws.com/#{options.environment}/latest-version.txt"
      klientLatest     :
        public         : "https://koding-klient.s3.amazonaws.com/#{options.environment}/latest-version.txt"
      kodingBase       :
        public         : "#{options.customDomain.public}"
        private        : "#{options.customDomain.local}"
      tunnelServer     :
        public         : "#{options.tunnelUrl}/kite"
    routes             :
      'dev.koding.com' : '127.0.0.1'

  KONFIG =
    serviceHost                   : options.serviceHost
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
    facebook                      : credentials.facebook
    slack                         : credentials.slack
    sneakerS3                     : credentials.sneakerS3
    embedly                       : credentials.embedly
    googleapiServiceAccount       : credentials.googleapiServiceAccount
    jwt                           : credentials.jwt
    papertrail                    : credentials.papertrail
    mailgun                       : credentials.mailgun
    helpscout                     : credentials.helpscout
    awsKeys                       : credentials.awsKeys
    segment                       : credentials.segment
    dummyAdmins                   : credentials.dummyAdmins
    countly                       : credentials.countly
    clearbit                      : credentials.clearbit
    wufoo                         : credentials.wufoo

    gitlab                        : gitlab
    regions                       : regions
    tunnelproxymanager            : tunnelproxymanager
    tunnelserver                  : tunnelserver
    marketingPagesURL             : marketingPagesURL
    socialapi                     : socialapi
    goKoding                      : goKoding
    githubapi                     : githubapi
    email                         : email
    kloud                         : kloud
    kontrol                       : kontrol
    gatekeeper                    : gatekeeper
    recaptcha                     : recaptcha
    uri                           : { address: options.customDomain.public }
    # TODO: average request count per hour for a user should be measured and a reasonable limit should be set
    nodejsRateLimiter             : { enabled: no,  guestRules: [{ interval: 3600, limit: 5000 }], userRules: [{ interval: 3600, limit: 10000 }] } # limit: request limit per rate limit window, interval: rate limit window duration in seconds
    nodejsRateLimiterForApi       : { enabled: yes, guestRules: [{ interval: 60,   limit: 5 }],    userRules: [{ interval: 60,   limit: 60 }] }    # limit: request limit per rate limit window, interval: rate limit window duration in seconds
    webserver                     : { port: 8080 }
    social                        : { port: 3030, login: "#{credentials.rabbitmq.login}", queueName: options.socialQueueName, kitePort: 8760, kiteKey: "#{credentials.kiteHome}/kite.key" }
    boxproxy                      : { port: parseInt(options.publicPort, 10) }
    sessionCookie                 : { maxAge: 1000 * 60 * 60 * 24 * 14, secure: options.secureCookie }
    troubleshoot                  : { recipientEmail: 'can@koding.com' }
    collaboration                 : { timeout: 1 * 60 * 1000 }
    client                        : { watch: yes, version: options.version, includesPath:'client' , indexMaster: 'index-master.html' , index: 'default.html' , useStaticFileServer: no , staticFilesBaseUrl: "#{options.customDomain.public}:#{options.customDomain.port}" }

    nginx: options.nginx

    ci  : credentials.ci
    test: credentials.test

  KONFIG.countlyPath = options.countlyPath if options.countlyPath
  return KONFIG
