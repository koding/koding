config =
  _selfConfig :
    defaultConfig : "dev-new"
  kite :
    applications :
      name              : 1
      pidPath           : 1
      logFile           : 1
      amqp            :
        host            : 1
        login           : 1
        password        : 1
      apiUri            : 1
      usersPath         : 1
      vhostDir          : 1
      defaultDomain     : 1
      minAllowedUid     : 1
      debugApi          : 1      
    databases    :
      name              : 1
      pidPath           : 1
      logFile           : 1
      port              : 1
      amqp                  :
        host                : 1
        login               : 1
        password            : 1
      apiUri            : 1
      mysql             :
        usersPath       : 1
        backupDir       : 1
        databases       :
          mysql         : [{ host : 1, user : 1, password:1}]
      mongo             :
        databases       :
          mongodb       : [{ host : 1, user : 1, password:1}]    
          hello         : 1
      hola: 1
    sharedHosting :
      name                  : 1
      pidPath               : 1
      logFile               : 1
      amqp                  :
        host                : 1
        login               : 1
        password            : 1
      apiUri                : 1
      usersPath             : 1
      vhostDir              : 1
      suspendDir            : 1
      defaultVhostFiles     : 1
      freeUsersGroup        : 1
      liteSpeedUser         : 1
      defaultDomain         : 1
      minAllowedUid         : 1
      debugApi              : 1
      processBaseDir        : 1
      cagefsctl             : 1
      baseMountDir          : 1
      maxAllowedRemotes     : 1
      usersMountsFile       : 1
      encryptKey            : 1
      ftpfs                 :
        curlftpfs           : 1
        opts                : 1
      sshfs                 :
        sshfscmd            : 1
        opts                : 1
        optsWithKey         : 1
      lsws                  :
        baseDir             : 1
        controllerPath      : 1
        lsMasterConfig      : 1
        configFilePath      : 1
        minRestartInterval  : 1
      ldap                  :
        ldapUrl             : 1
        rootUser            : 1
        rootPass            : 1
        groupDN             : 1
        userDN              : 1
        freeUID             : 1
        freeGroup           : 1
      FileSharing           :
        baseSharedDir       : 1
        baseDir             : 1
        setfacl             : 1      
  main :
    uri           :
      address     : 1
    projectRoot   : 1
    version       : 1
    webserver     :
      login       : 1
      port        : []
      clusterSize : 1
      queueName   : 1
    mongo         : 1
    runGoBroker   : 1
    buildClient   : 1
    misc          :
      claimGlobalNamesForUsers: 1
      updateAllSlugs : 1
      debugConnectionErrors: 1
    uploads       :
      enableStreamingUploads: 1
      distribution: 1
      s3          :
        awsAccountId        : 1
        awsAccessKeyId      : 1
        awsSecretAccessKey  : 1
        bucket              : 1
    librato :
      push      : 1
      email     : 1
      token     : 1
      interval  : 1
    bitly :
      username  : 1
      apiKey    : 1
    authWorker    :
      login       : 1
      queueName   : 1
      authResourceName: 1
      numberOfWorkers: 1
    social        :
      login       : 1
      numberOfWorkers: 1
      watch       : 1
      queueName   : 1
    feeder        :
      queueName   : 1
      exchangePrefix: 1
      numberOfWorkers: 1
    presence      :
      exchange    : 1
    client        :
      pistachios  : 1
      version     : 1
      minify      : 1
      watch       : 1
      js          : 1
      css         : 1
      indexMaster: 1
      index       : 1
      includesFile: 1
      useStaticFileServer: 1
      staticFilesBaseUrl: 1
      runtimeOptions:
        resourceName: 1
        suppressLogs: 1
        version   : 1
        mainUri   : 1
        broker    :
          sockJS  : 1
        apiUri    : 1
        appsUri   : 1
    mq            :
      host        : 1
      login       : 1
      password    : 1
      heartbeat   : 1
      vhost       : 1
    kites:
      disconnectTimeout: 1
      vhost       : 1
    email         :
      host        : 1
      protocol    : 1
      defaultFromAddress: 1
    guests        :
      poolSize        : 1
      batchSize       : 1
      cleanupCron     : 1
    logger            :
      mq              :
        host          : 1
        login         : 1
        password      : 1
    pidFile       : 1


module.exports = config