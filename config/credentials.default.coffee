randomstring = require 'randomstring'

module.exports = (options) ->
  kiteHome = '$KONFIG_PROJECTROOT/generated/kite_home/koding'

  kodingdev_master =
    accessKeyId: ''
    secretAccessKey: ''

  awsKeys =
    kodingdev_master: kodingdev_master
    # s3 full access
    worker_terraformer: kodingdev_master
    # s3 put only to koding-client bucket
    worker_koding_client_s3_put_only: kodingdev_master
    # admin
    worker_test: kodingdev_master
    # s3 put only
    worker_test_data_exporter: kodingdev_master
    # AmazonRDSReadOnlyAccess
    worker_rds_log_parser: kodingdev_master
    # ELB & EC2 -> AmazonEC2ReadOnlyAccess
    worker_multi_ssh: kodingdev_master
    # AmazonEC2FullAccess
    worker_test_instance_launcher: kodingdev_master
    # TunnelProxyPolicy
    worker_tunnelproxymanager: kodingdev_master
    worker_tunnelproxymanager_route53: kodingdev_master
    #Encryption and Storage on S3
    worker_sneakerS3 : kodingdev_master

  mongo = "#{options.serviceHost}:27017/koding"
  redis =
    host: options.serviceHost
    port: '6379'
    db: 0
    url : "#{options.serviceHost}:6379"
  rabbitmq =
    host: "#{options.serviceHost}"
    port: 5672
    apiAddress: "#{options.serviceHost}"
    apiPort: '15672'
    login: 'guest'
    componentUser: 'guest'
    password: 'guest'
    heartbeat: 10
    vhost: '/'
  postgres =
    host: "#{options.serviceHost}"
    port: '5432'
    username: 'socialapplication'
    password: 'socialapplication'
    dbname: 'social'
  kontrolPostgres =
    host: "#{options.serviceHost}"
    port: 5432
    username: 'kontrolapplication'
    password: 'kontrolapplication'
    dbname: 'social'
    connecttimeout: 20
  pubnub =
    publishkey: ''
    subscribekey: ''
    secretkey: ''
    serverAuthKey: ''
    origin: 'pubsub.pubnub.com'
    enabled: no
    ssl: no
  terraformer =
    port: 2300
    region: options.region
    environment: options.environment
    secretKey: randomstring.generate()
    aws:
      key: awsKeys.worker_terraformer.accessKeyId
      secret: awsKeys.worker_terraformer.secretAccessKey
      bucket: "kodingdev-terraformer-state-#{options.configName}"
    localStorePath:  '$KONFIG_PROJECTROOT/go/data/terraformer'
  googleapiServiceAccount =
    clientId: ''
    clientSecret: ''
    serviceAccountEmail: ''
    serviceAccountKeyFile: ''
  github =
    clientId: ''
    clientSecret: ''
    redirectUri: 'http://dev.koding.com:8090/-/oauth/github/callback'
  gitlab =
    host: ''
    port: ''
    applicationId: ''
    applicationSecret: ''
    team: 'gitlab'
    redirectUri: ''
    systemHookToken: ''
    hooksEnabled: no
    allowPrivateOAuthEndpoints: no
  facebook =
    clientId: ''
    clientSecret: ''
    redirectUri: 'http://dev.koding.com:8090/-/oauth/facebook/callback'
  mailgun =
    domain: ''
    privateKey: ''
    publicKey: ''
    unsubscribeURL: ''
  slack =
    clientId: ''
    clientSecret: ''
    redirectUri: ''
    verificationToken: ''
  google =
    client_id: ''
    client_secret: ''
    redirect_uri: 'http://dev.koding.com:8090/-/oauth/google/callback'
    apiKey: ''
  twitter =
    key: ''
    secret: ''
    redirect_uri: 'http://dev.koding.com:8090/-/oauth/twitter/callback'
    request_url: 'https://twitter.com/oauth/request_token'
    access_url: 'https://twitter.com/oauth/access_token'
    secret_url: 'https://twitter.com/oauth/authenticate?oauth_token='
    version: '1.0'
    signature: 'HMAC-SHA1'
  linkedin =
    client_id: ''
    client_secret: ''
    redirect_uri: 'http://dev.koding.com:8090/-/oauth/linkedin/callback'
  datadog =
    api_key: ''
    app_key: ''
  embedly =
    apiKey: ''
  jwt =
    secret: 'somesecretkeyhere'
    confirmExpiresInMinutes: 10080
  papertrail =
    destination: 'logs3.papertrailapp.com:13734'
    groupId: 2199093
    token: ''
  helpscout =
    apiKey: ''
    baseUrl: 'https://api.helpscout.net/v1'
  sneakerS3 =
    awsSecretAccessKey: "#{awsKeys.worker_sneakerS3.secretAccessKey}"
    awsAccessKeyId: "#{awsKeys.worker_sneakerS3.accessKeyId}"
    sneakerS3Path: 's3://kodingdev-credential/'
    sneakerMasterKey: ''
    awsRegion: ''
  stripe =
    secretToken: ''
    publicToken: ''
  recaptcha =
    secret: ''
    public: ''
    invisible_secret: ''
    invisible_public: ''
  segment = ''
  kontrol =
    publicKey: '$KONFIG_PROJECTROOT/generated/private_keys/kontrol/kontrol.pub'
    privateKey: '$KONFIG_PROJECTROOT/generated/private_keys/kontrol/kontrol.pem'
  kloud =
    publicKey: kontrol.publicKey
    privateKey: kontrol.privateKey
    secretKey: randomstring.generate()
    terraformerSecretKey: terraformer.secretKey
    userPublicKey: '$KONFIG_PROJECTROOT/generated/private_keys/kloud/kloud.pub'
    userPrivateKey: '$KONFIG_PROJECTROOT/generated/private_keys/kloud/kloud.pem'
  dummyAdmins = ['superadmin', 'admin', 'koding']

  countlyApiPort = '32768'
  countly  =
    host: "http://#{options.serviceHost}:#{countlyApiPort}/countly"
    apiPort: countlyApiPort
    email: 'admin@countly.com'
    username: 'admin'
    apiKey: 'e6bfab40a224d55a2f5d40c83abc7ed4'
    appName: 'default'
    appOwner: '58bf0614a68a980015486d03'
    appId: '58bf06bd6cba850047ac9f19'
    appKey: 'b41e02136be60a58b9b7459ad89030537a58e099'
    disabled: yes
    fixApps: no

  clearbit = '9d961e7ac862a6bc430f783da5cf9422'
  intercomAppId = ''
  wufoo = ''

  return {
    kiteHome
    awsKeys
    mongo
    redis
    rabbitmq
    postgres
    kontrolPostgres
    pubnub
    terraformer
    googleapiServiceAccount
    github
    gitlab
    facebook
    mailgun
    slack
    google
    twitter
    linkedin
    datadog
    embedly
    jwt
    papertrail
    helpscout
    sneakerS3
    stripe
    recaptcha
    segment
    kontrol
    kloud
    dummyAdmins
    countly
    clearbit
    intercomAppId
    wufoo
  }
