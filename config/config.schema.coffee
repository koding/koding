config =
  _selfConfig :
    defaultConfig : "vagrant"
  kite :
    applications :
      name              : 1
      pidPath           : 1
      logFile           : 1
      amqp            :
        host            : 1
        login           : 1
        password        : 1
        heartbeat       : 1
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
        heartbeat           : 1
      apiUri            : 1
      mysql             :
        usersPath       : 1
        backupDir       : 1
        databases       :
          mysql         : [{ host : 1, user : 1, password:1}]
      mongo             :
        databases       :
          mongodb       : [{ host : 1, user : 1, password:1}]
  main            :
    environment   : 1
    regions       :
      vagrant     : 1
      sj          : 1
      aws         : 1
      premium     : 1
    version       : 1
    aws           :
      key         : 1
      secret      : 1
    uri           :
      address     : 1
    userSitesDomain: 1
    containerSubnet: 1
    vmPool        : 1
    projectRoot   : 1
    webserver     :
      useCacheHeader: 1
      login       : 1
      port        : []
      clusterSize : 1
      queueName   : 1
      watch       : 1
    socialApiUrl  : 1
    sourceServer  :
      enabled     : 1
      port        : 1
    mongo         : 1
    mongoKontrol  : 1
    mongoReplSet  : 1
    mongoMinWrites: 1
    neo4j         :
      read        : 1
      write       : 1
      port        : 1
    runNeo4jFeeder: 1
    runGoBroker   : 1
    runGoBrokerKite: 1
    runPremiumBrokerKite: 1
    runPremiumBroker: 1
    runKontrol    : 1
    runRerouting  : 1
    runPersistence: 1
    compileGo     : 1
    buildClient   : 1
    runOsKite     : 0
    runTerminalKite: 0
    runProxy      : 0
    redis         : 1
    subscriptionEndpoint   : 1
    misc          :
      claimGlobalNamesForUsers: 1
      updateAllSlugs : 1
      debugConnectionErrors: 1
    bitly :
      username  : 1
      apiKey    : 1
    authWorker    :
      authExchange: 1
      authAllExchange: 1
      login           : 1
      queueName       : 1
      numberOfWorkers : 1
      watch           : 1
    guestCleanerWorker    :
      enabled             : 1
      login               : 1
      queueName           : 1
      numberOfWorkers     : 1
      watch               : 1
      cronSchedule        : 1
      usageLimitInMinutes : 1
    elasticSearch         :
      host                : 1
      port                : 1
      enabled             : 1
      queue               : 1
    emailConfirmationCheckerWorker :
      enabled             : 1
      login               : 1
      queueName           : 1
      numberOfWorkers     : 1
      watch               : 1
      cronSchedule        : 1
      usageLimitInMinutes : 1
    sitemapWorker         :
      enabled             : 1
      login               : 1
      queueName           : 1
      numberOfWorkers     : 1
      watch               : 1
      cronSchedule        : 1
    topicModifier         :
      cronSchedule        : 1
    social        :
      login       : 1
      numberOfWorkers: 1
      watch       : 1
      queueName   : 1
      verbose     : 1
      kitePort    : 1
    log           :
      login       : 1
      numberOfWorkers: 1
      watch       : 1
      queueName   : 1
      verbose     : 1
      run         : 1
      runWorker   : 1
    graphFeederWorker :
      numberOfWorkers : 1
    presence        :
      exchange      : 1
    client          :
      version       : 1
      watch         : 1
      watchDuration : 1
      includesPath  : 1
      indexMaster   : 1
      index         : 1
      useStaticFileServer: 1
      staticFilesBaseUrl: 1
      runtimeOptions  :
        kites:
          disableWebSocketByDefault: 1
          stack:
            force: 1
            newKites: 1
          kontrol:
            username: 1
          os:
            version: 1
          terminal:
            version: 1
        osKitePollingMs: 1
        userIdleMs: 1
        sessionCookie :
          maxAge      : 1
          secure      : 1
        environment   : 1
        activityFetchCount : 1
        authExchange  : 1
        github        :
          clientId    : 1
        embedly       :
          apiKey      : 1
        userSitesDomain: 1
        useNeo4j      : 1
        logToExternal : 1
        logToInternal : 1
        resourceName  : 1
        logResourceName: 1
        socialApiUri  : 1
        logApiUri     : 1
        suppressLogs  : 1
        version       : 1
        mainUri       : 1
        broker        :
          servicesEndpoint: 1
        premiumBroker        :
          servicesEndpoint: 1
        brokerKite    :
          servicesEndpoint: 1
          brokerExchange: 1
        premiumBrokerKite:
          servicesEndpoint : 1
          brokerExchange   : 1
        apiUri        : 1
        appsUri       : 1
        uploadsUri    : 1
        uploadsUriForGroup: 1
        sourceUri     : 1
        newkontrol    :
          url         : 1
        fileFetchTimeout: 1
        externalProfiles  :
          github          :
            nicename      : 1
            urlLocation   : 1
          odesk           :
            nicename      : 1
            urlLocation   : 1
          facebook        :
            nicename      : 1
            urlLocation   : 1
          google          :
            nicename      : 1
          linkedin        :
            nicename      : 1
          twitter         :
            nicename      : 1
          # bitbucket     :
          #   nicename    : 1
        troubleshoot      :
          idleTime        : 1
          externalUrl     : 1
        recaptcha         : 1
        hangouts          :
          projectId       : 1
      # authResourceName : DO NOT COMMIT THIS BACK IN NOR DELETE. IT KEEPS COMING BACK. devrim.
    mq            :
      host        : 1
      port        : 1
      apiPort     : 1
      apiAddress  : 1
      login       : 1
      componentUser: 1
      password    : 1
      heartbeat   : 1
      vhost       : 1
    broker        :
      name        : 1
      serviceGenericName: 1
      ip          : 1
      port        : 1
      certFile    : 1
      keyFile     : 1
      webProtocol : 1
      authExchange: 1
      authAllExchange: 1
      failoverUri : 1
    premiumBroker :
      name        : 1
      serviceGenericName: 1
      ip          : 1
      port        : 1
      certFile    : 1
      keyFile     : 1
      webProtocol : 1
      authExchange: 1
      authAllExchange: 1
      failoverUri : 1
    brokerKite    :
      name        : 1
      serviceGenericName: 1
      ip          : 1
      port        : 1
      certFile    : 1
      keyFile     : 1
      webProtocol : 1
      authExchange: 1
      authAllExchange: 1
      failoverUri : 1
    premiumBrokerKite :
      name        : 1
      serviceGenericName: 1
      ip          : 1
      port        : 1
      certFile    : 1
      keyFile     : 1
      webProtocol : 1
      authExchange: 1
      authAllExchange: 1
      failoverUri : 1
    kites:
      disconnectTimeout: 1
      vhost       : 1
    email         :
      host        : 1
      protocol    : 1
      defaultFromAddress: 1
    emailWorker   :
      cronInstant : 1
      cronDaily   : 1
      run         : 1
      forcedRecipient : 1
      maxAge      : 1
    emailSender   :
      run         : 1
    guests        :
      poolSize        : 1
      batchSize       : 1
      cleanupCron     : 1
    pidFile       : 1
    etcd            : [{ host : 1, port : 1}]
    newkites      :
      useTLS          : 1
      certFile        : 1
      keyFile         : 1
    newkontrol      :
      port            : 1
      useTLS          : 1
      certFile        : 1
      keyFile         : 1
      publicKeyFile   : 1
      privateKeyFile  : 1
    proxyKite       :
      domain        : 1
      certFile      : 1
      keyFile       : 1
    kontrold        :
      vhost         : 1
      overview      :
        apiHost     : 1
        apiPort     : 1
        port        : 1
        kodingHost  : 1
        socialHost  : 1
      api           :
        port        : 1
        url         : 1
      proxy         :
        port        : 1
        portssl     : 1
        ftpip       : 1
    recurly         :
      apiKey        : 1
      loggedRequests: 1
    embedly         :
      apiKey        : 1
    followFeed      :
      host          : 1
      port          : 1
      componentUser : 1
      password      : 1
      vhost         : 1
    opsview	        :
      push	        : 1
      host          : 1
      bin           : 1
      conf          : 1
    github          :
      clientId      : 1
      clientSecret  : 1
    odesk           :
      key           : 1
      secret        : 1
      request_url   : 1
      access_url    : 1
      secret_url    : 1
      version       : 1
      signature     : 1
      redirect_uri  : 1
    facebook        :
      clientId      : 1
      clientSecret  : 1
      redirectUri   : 1
    google          :
      client_id     : 1
      client_secret : 1
      redirect_uri  : 1
    statsd          :
      use           : 1
      ip            : 1
      port          : 1
    graphite        :
      use           : 1
      host          : 1
      port          : 1
    linkedin        :
      client_id     : 1
      client_secret : 1
      redirect_uri  : 1
    twitter         :
      key           : 1
      secret        : 1
      redirect_uri  : 1
      request_url   : 1
      access_url    : 1
      secret_url    : 1
      version       : 1
      signature     : 1
    mixpanel        : 1
    rollbar         : 1
    slack           :
      token         : 1
      channel       : 1
    logLevel        :
      neo4jfeeder   : 1
      oskite        : 1
      terminal      : 1
      kontrolproxy  : 1
      kontroldaemon : 1
      userpresence  : 1
      vmproxy       : 1
      graphitefeeder: 1
      sync          : 1
      topicModifier : 1
      postModifier  : 1
      router        : 1
      rerouting     : 1
      overview      : 1
      amqputil      : 1
      rabbitMQ      : 1
      ldapserver    : 1
      broker        : 1
    defaultVMConfigs:
      freeVM        :
        storage     : 1
        ram         : 1
        cpu         : 1
    sessionCookie   :
      maxAge        : 1
      secure        : 1
    troubleshoot    :
      recipientEmail: 1
    recaptcha       : 1
module.exports = config
