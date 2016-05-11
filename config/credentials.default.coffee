module.exports = (options) ->
  kiteHome = "#{options.projectRoot}/generated/kite_home/koding"

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
    worker_tunnelproxymanager: kodingdev_master_2016_05 # Name worker_tunnelproxymanager_dev
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
    port: "5432"
    username: "socialapp_2016_05"
    password: "socialapp_2016_05"
    dbname: "social"
  kontrolPostgres =
    host: "#{options.serviceHost}"
    port: 5432
    username: "kontrolapp_2016_05"
    password: "kontrolapp_2016_05"
    dbname: "social"
    connecttimeout: 20
  pubnub =
    publishkey: "pub-c-5b987056-ef0f-457a-aadf-87b0488c1da1"
    subscribekey: "sub-c-70ab5d36-0b13-11e5-8104-0619f8945a4f"
    secretkey: "sec-c-MWFhYTAzZWUtYzg4My00ZjAyLThiODEtZmI0OTFkOTk0YTE0"
    serverAuthKey: "46fae3cc-9344-4edb-b152-864ba567980c7960b1d8-31dd-4722-b0a1-59bf878bd551"
    origin: "pubsub.pubnub.com"
    enabled:  yes
    ssl: no
  terraformer =
    port : 2300
    bucket: "kodingdev-terraformer-state-#{options.configName}"
    localstorepath:  "#{options.projectRoot}/go/data/terraformer"
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
  odesk =
    key: ''
    secret: ''
    request_url: "https://www.upwork.com/api/auth/v1/oauth/token/request"
    access_url: "https://www.upwork.com/api/auth/v1/oauth/token/access"
    secret_url: "https://www.upwork.com/services/api/auth?oauth_token="
    version: "1.0"
    signature: "HMAC-SHA1"
    redirect_uri: "http://dev.koding.com:8090/-/oauth/odesk/callback"
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
    port: "6700"
    secretKey: ""
  vmwatcher =
    secretKey: ""
  recurly =
    apiKey: ""
    loggedRequests: "/^(subscriptions|transactions)/"
  segment = ''
  kontrol =
    publicKeyFile: "#{options.projectRoot}/generated/private_keys/kontrol/kontrol.pem"
    privateKeyFile: "#{options.projectRoot}/generated/private_keys/kontrol/kontrol.pub"
  kloud =
    userPrivateKeyFile: "#{options.projectRoot}/generated/private_keys/kloud/kloud.pem"
    userPublicKeyfile: "#{options.projectRoot}/generated/private_keys/kloud/kloud.pub"
    privateKeyFile: kontrol.privateKeyFile
    publicKeyFile: kontrol.publicKeyFile
    secretKey: ''

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
    odesk
    facebook
    mailgun
    slack
    google
    twitter
    linkedin
    datadog
    embedly
    rollbar
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
    helpscout
    recurly
    segment
    kontrol
    kloud
    vmwatcher
  }
