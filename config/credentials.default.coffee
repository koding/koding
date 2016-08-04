module.exports = (options) ->
  kiteHome = "$KONFIG_PROJECTROOT/generated/kite_home/koding"

  kodingdev_master_2016_05 =
    accessKeyId: ""
    secretAccessKey: ""

  awsKeys =
    kodingdev_master_2016_05: kodingdev_master_2016_05
    # s3 full access
    worker_terraformer: kodingdev_master_2016_05
    # s3 put only to koding-client bucket
    worker_koding_client_s3_put_only: kodingdev_master_2016_05
    # admin
    worker_test: kodingdev_master_2016_05
    # s3 put only
    worker_test_data_exporter: kodingdev_master_2016_05
    # AmazonRDSReadOnlyAccess
    worker_rds_log_parser: kodingdev_master_2016_05
    # ELB & EC2 -> AmazonEC2ReadOnlyAccess
    worker_multi_ssh: kodingdev_master_2016_05
    # AmazonEC2FullAccess
    worker_test_instance_launcher: kodingdev_master_2016_05
    # TunnelProxyPolicy
    worker_tunnelproxymanager: kodingdev_master_2016_05
    worker_tunnelproxymanager_route53: kodingdev_master_2016_05
    #Encryption and Storage on S3
    worker_sneakerS3 : kodingdev_master_2016_05
    vm_vmwatcher:     # vm_vmwatcher_dev
      accessKeyId: ""
      secretAccessKey: ""
    vm_kloud:         # vm_kloud_dev
      accessKeyId: ""
      secretAccessKey: ""

  slKeys =
    vm_kloud:
      username: ""
      apiKey: ""
  mongo = "#{options.serviceHost}:27017/koding"
  redis =
    host: "#{options.serviceHost}"
    port: "6379"
    db: 0
    url : "#{options.serviceHost}:6379"
  monitoringRedis = redis
  rabbitmq =
    host: "#{options.serviceHost}"
    port: 5672
    apiAddress: "#{options.serviceHost}"
    apiPort: "15672"
    login: "guest"
    componentUser: "guest"
    password: "guest"
    heartbeat: 10
    vhost: "/"
  algolia =
    appId: ''
    apiSecretKey: ''
    apiSearchOnlyKey: ''
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
    publishkey: ""
    subscribekey: ""
    secretkey: ""
    serverAuthKey: ""
    origin: "pubsub.pubnub.com"
    enabled:  yes
    ssl: no
  terraformer =
    port: 2300
    region: options.region
    environment: options.environment
    secretKey: ''
    aws:
      key: awsKeys.worker_terraformer.accessKeyId
      secret: awsKeys.worker_terraformer.secretAccessKey
      bucket: "kodingdev-terraformer-state-#{options.configName}"
    localStorePath:  "$KONFIG_PROJECTROOT/go/data/terraformer"
  paymentwebhook =
    customersKey: 'R1PVxSPvjvDSWdlPRVqRv8IdwXZB'
    secretKey: "paymentwebhooksecretkey-#{options.configName}"
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
  facebook =
    clientId: ''
    clientSecret: ''
    redirectUri: "http://dev.koding.com:8090/-/oauth/facebook/callback"
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
    redirect_uri: "http://dev.koding.com:8090/-/oauth/google/callback"
  twitter =
    key: ''
    secret: ''
    redirect_uri: "http://dev.koding.com:8090/-/oauth/twitter/callback"
    request_url: "https://twitter.com/oauth/request_token"
    access_url: "https://twitter.com/oauth/access_token"
    secret_url: "https://twitter.com/oauth/authenticate?oauth_token="
    version: "1.0"
    signature: "HMAC-SHA1"
  linkedin =
    client_id: ''
    client_secret: ''
    redirect_uri: "http://dev.koding.com:8090/-/oauth/linkedin/callback"
  datadog =
    api_key: ''
    app_key: ''
  embedly =
    apiKey: ''
  siftScience = ''
  siftSciencePublic = ''
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
    sneakerS3Path: "s3://kodingdev-credential/"
    sneakerMasterKey: ''
    awsRegion: ''
  stripe =
    secretToken: ''
    publicToken: ''
  recaptcha =
    secret: ''
    public: ''
  paypal =
    username: ''
    password: ''
    signature: ''
    returnUrl: "#{options.customDomain.public}/-/payments/paypal/return"
    cancelUrl: "#{options.customDomain.public}/-/payments/paypal/cancel"
    isSandbox: yes
    formUrl: 'https://www.sandbox.paypal.com/incontext'
  janitor =
    port: '6700'
    secretKey: ''
  vmwatcher =
    secretKey: ''
  segment = ''
  kontrol =
    publicKey: "$KONFIG_PROJECTROOT/generated/private_keys/kontrol/kontrol.pub"
    privateKey: "$KONFIG_PROJECTROOT/generated/private_keys/kontrol/kontrol.pem"
  kloud =
    publicKey: kontrol.publicKey
    privateKey: kontrol.privateKey
    secretKey: ''
    janitorSecretKey: janitor.secretKey
    vmwatcherSecretKey: vmwatcher.secretKey
    terraformerSecretKey: terraformer.secretKey
    userPublicKey: "$KONFIG_PROJECTROOT/generated/private_keys/kloud/kloud.pub"
    userPrivateKey: "$KONFIG_PROJECTROOT/generated/private_keys/kloud/kloud.pem"
  dummyAdmins = ['superadmin', 'admin', 'koding']
  druid =
    host : options.serviceHost
    port : 8090
  clearbit = '9d961e7ac862a6bc430f783da5cf9422'
  intercomAppId = ''

  return {
    kiteHome
    awsKeys
    slKeys
    mongo
    redis
    monitoringRedis
    rabbitmq
    algolia
    postgres
    kontrolPostgres
    pubnub
    terraformer
    paymentwebhook
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
    siftScience
    siftSciencePublic
    jwt
    papertrail
    helpscout
    sneakerS3
    stripe
    recaptcha
    paypal
    janitor
    segment
    kontrol
    kloud
    vmwatcher
    dummyAdmins
    druid
    clearbit
  }
