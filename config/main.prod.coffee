zlib                  = require 'compress-buffer'
traverse              = require 'traverse'
log                   = console.log

Configuration = (options={}) ->

  prod_simulation_server = "localhost"

  hostname            = options.hostname       or "prod-v1_2_4-anna"
  publicHostname      = options.publicHostname or "https://koding.me"
  region              = options.region         or "aws"
  configName          = options.configName     or "prod"
  environment         = options.environment    or "prod"
  projectRoot         = options.projectRoot    or "/opt/koding"
  version             = options.tag
  tag                 = options.tag
  publicIP            = options.publicIP       or "*"

  # prod mongo "mongodb://dev:k9lc4G1k32nyD72@172.16.3.9,172.16.3.10,172.16.3.15/koding?replicaSet=koodingrs0&readPreference=primaryPreferred"
  mongo               = "#{prod_simulation_server}:27017/koding"
  redis               = {host     : "prod0.1ia3pb.0001.use1.cache.amazonaws.com"   , port : "6379" }
  socialapi           = {proxyUrl : "http://localhost:7000"       , port : 7000 , clusterSize : 5,     configFilePath : "#{projectRoot}/go/src/socialapi/config/prod.toml" }
  rabbitmq            = {host     : "#{prod_simulation_server}"   , port : 5672 , apiPort     : 15672, login          : "guest", password : "guest", vhost:"/"}
  etcd                = "10.0.0.126:4001, 10.0.0.127:4001, 10.0.0.128:4001"

  customDomain        =
    public            : "http://#{hostname}"
    public_           : "#{hostname}"
    local             : "http://localhost"
    local_            : "localhost"
    port              : 80


  # KONTROL DEPLOYMENT IS SEPARATED FROM PROD DEPLOY.
  kontrol             =
    url               : "https://kontrol.koding.com/kite"
    port              : 443
    useTLS            : no
    certFile          : ""
    keyFile           : ""
    publicKeyFile     : "#{projectRoot}/certs/test_kontrol_rsa_public.pem"
    privateKeyFile    : "#{projectRoot}/certs/test_kontrol_rsa_private.pem"

  broker              =
    name              : "broker"
    serviceGenericName: "broker"
    ip                : ""
    webProtocol       : "http:"
    host              : customDomain.public
    port              : 8008
    certFile          : ""
    keyFile           : ""
    authExchange      : "auth"
    authAllExchange   : "authAll"
    failoverUri       : customDomain.public

  userSitesDomain     = "#{customDomain.public_}"                 # this is for domain settings on environment backend eg. kd.io

  socialQueueName     = "koding-social-#{configName}"
  logQueueName        = socialQueueName+'log'

  regions             =
    kodingme          : "#{configName}"
    vagrant           : "vagrant"
    sj                : "sj"
    aws               : "aws"
    premium           : "vagrant"



  KONFIG              =
    environment       : environment
    regions           : regions
    region            : region
    hostname          : hostname
    publicHostname    : publicHostname
    version           : version
    broker            : broker
    uri               : {address: "#{customDomain.public}:#{customDomain.port}"}
    userSitesDomain   : userSitesDomain
    projectRoot       : projectRoot
    socialapi         : socialapi        # THIS IS WHERE WEBSERVER & SOCIAL WORKER KNOW HOW TO CONNECT TO SOCIALAPI
    mongo             : mongo
    redis             : "#{redis.host}:#{redis.port}"
    misc              : {claimGlobalNamesForUsers: no, updateAllSlugs : no, debugConnectionErrors: yes}

    # -- WORKER CONFIGURATION -- #

    presence          : {exchange      : 'services-presence'}
    webserver         : {port          : 3000                        , useCacheHeader: no}
    authWorker        : {login         : "#{rabbitmq.login}"         , queueName : socialQueueName+'auth', authExchange      : "auth"             , authAllExchange : "authAll"}
    mq                : {host          : "#{rabbitmq.host}"          , port      : rabbitmq.port         , apiAddress        : "#{rabbitmq.host}" , apiPort         : "#{rabbitmq.apiPort}", login:"#{rabbitmq.login}",componentUser:"#{rabbitmq.login}",password: "#{rabbitmq.password}",heartbeat: 0, vhost: "#{rabbitmq.vhost}"}
    emailWorker       : {cronInstant   : '*/10 * * * * *'            , cronDaily : '0 10 0 * * *'        , run               : no                 , forcedRecipient : undefined, maxAge: 3}
    elasticSearch     : {host          : "#{prod_simulation_server}" , port      : 9200                  , enabled           : no                 , queue           : "elasticSearchFeederQueue"}
    social            : {port          : 3030                        , login     : "#{rabbitmq.login}"   , queueName         : socialQueueName    , kitePort        : 8765 }
    email             : {host          : "#{customDomain.public_}"    , protocol  : 'http:'               , defaultFromAddress: 'hello@koding.com' }
    newkites          : {useTLS        : no                          , certFile  : ""                    , keyFile: "#{projectRoot}/kite_home/production/kite.key"}
    log               : {login         : "#{rabbitmq.login}"         , queueName : logQueueName}
    boxproxy          : {port          : 80 }
    sourcemaps        : {port          : 3526 }
    appsproxy         : {port          : 3500 }

    kloud             : {port          : 5500                        , privateKeyFile : kontrol.privateKeyFile, publicKeyFile: kontrol.publicKeyFile, kontrolUrl: "#{"reads from kite.key by default."}"  }
    emailConfirmationCheckerWorker     : {enabled: no                , login : "#{rabbitmq.login}"        , queueName: socialQueueName+'emailConfirmationCheckerWorker',cronSchedule: '0 * * * * *',usageLimitInMinutes  : 60}

    newkontrol        : kontrol

    # -- MISC SERVICES --#
    recurly           : {apiKey        : '4a0b7965feb841238eadf94a46ef72ee'            , loggedRequests: /^(subscriptions|transactions)/}
    opsview           : {push          : no                                            , host          : '', bin: null, conf: null}
    github            : {clientId      : "f8e440b796d953ea01e5"                        , clientSecret  : "b72e2576926a5d67119d5b440107639c6499ed42"}
    odesk             : {key           : "639ec9419bc6500a64a2d5c3c29c2cf8"            , secret        : "549b7635e1e4385e",request_url: "https://www.odesk.com/api/auth/v1/oauth/token/request",access_url: "https://www.odesk.com/api/auth/v1/oauth/token/access",secret_url: "https://www.odesk.com/services/api/auth?oauth_token=",version: "1.0",signature: "HMAC-SHA1",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/odesk/callback"}
    facebook          : {clientId      : "475071279247628"                             , clientSecret  : "65cc36108bb1ac71920dbd4d561aca27", redirectUri  : "#{customDomain.host}:#{customDomain.port}/-/oauth/facebook/callback"}
    google            : {client_id     : "1058622748167.apps.googleusercontent.com"    , client_secret : "vlF2m9wue6JEvsrcAaQ-y9wq",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/google/callback"}
    twitter           : {key           : "aFVoHwffzThRszhMo2IQQ"                       , secret        : "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E",redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/twitter/callback",    request_url  : "https://twitter.com/oauth/request_token",    access_url   : "https://twitter.com/oauth/access_token",secret_url: "https://twitter.com/oauth/authenticate?oauth_token=",version: "1.0",signature: "HMAC-SHA1"}
    linkedin          : {client_id     : "f4xbuwft59ui"                                , client_secret : "fBWSPkARTnxdfomg", redirect_uri : "#{customDomain.host}:#{customDomain.port}/-/oauth/linkedin/callback"}
    slack             : {token         : "xoxp-2155583316-2155760004-2158149487-a72cf4", channel       : "C024LG80K"}
    statsd            : {use           : false                                         , ip            : "#{customDomain.host}", port: 8125}
    graphite          : {use           : false                                         , host          : "#{customDomain.host}", port: 2003}
    sessionCookie     : {maxAge        : 1000 * 60 * 60 * 24 * 14                      , secure        : no}
    logLevel          : {neo4jfeeder   : "notice", oskite: "info", terminal: "info"    , kontrolproxy  : "notice", kontroldaemon : "notice",userpresence  : "notice", vmproxy: "notice", graphitefeeder: "notice", sync: "notice", topicModifier : "notice",  postModifier  : "notice", router: "notice", rerouting: "notice", overview: "notice", amqputil: "notice",rabbitMQ: "notice",ldapserver: "notice",broker: "notice"}
    aws               : {key           : 'AKIAJSUVKX6PD254UGAA'                        , secret        : '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'}
    embedly           : {apiKey        : '94991069fb354d4e8fdb825e52d4134a'}
    troubleshoot      : {recipientEmail: "can@koding.com"}
    rollbar           : "71c25e4dc728431b88f82bd3e7a600c9"
    mixpanel          : "a57181e216d9f713e19d5ce6d6fb6cb3"

    #--- CLIENT-SIDE BUILD CONFIGURATION ---#

    client            : {watch: yes, version       : version, includesPath:'client', indexMaster: "index-master.html", index: "default.html", useStaticFileServer: no, staticFilesBaseUrl: "#{customDomain.public}:#{customDomain.port}"}

  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  KONFIG.client.runtimeOptions =
    kites             : require './kites.coffee'           # browser passes this version information to kontrol, so it connects to correct version of the kite.
    algolia: #TODO change these credentials
      appId: '8KD9RHY1OA'
      apiKey: 'e4a8ebe91bf848b67c9ac31a6178c64b'
      indexSuffix: ''
    logToExternal     : no                                 # rollbar, mixpanel etc.
    suppressLogs      : no
    logToInternal     : no                                 # log worker
    authExchange      : "auth"
    environment       : environment                        # this is where browser knows what kite environment to query for
    version           : version
    resourceName      : socialQueueName
    userSitesDomain   : userSitesDomain
    logResourceName   : logQueueName
    socialApiUri      : "/xhr"
    apiUri            : "/"
    mainUri           : "/"
    sourceMapsUri     : "/sourcemaps"
    appsUri           : "https://rest.kd.io"

    uploadsUri        : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup: 'https://koding-groups.s3.amazonaws.com'
    # logApiUri         : "#{customDomain.public}:4030/xhr"
    fileFetchTimeout  : 1000 * 15
    userIdleMs        : 1000 * 60 * 5
    embedly           : {apiKey       : "94991069fb354d4e8fdb825e52d4134a"     }
    broker            : {uri          : "/subscribe" }
    github            : {clientId     : "f8e440b796d953ea01e5" }
    newkontrol        : {url          : "#{kontrol.url}"}
    sessionCookie     : {maxAge       : 1000 * 60 * 60 * 24 * 14, secure: no   }
    troubleshoot      : {idleTime     : 1000 * 60 * 60          , externalUrl  : "https://s3.amazonaws.com/koding-ping/healthcheck.json"}
    externalProfiles  :
      google          : {nicename: 'Google'  }
      linkedin        : {nicename: 'LinkedIn'}
      twitter         : {nicename: 'Twitter' }
      odesk           : {nicename: 'oDesk'   , urlLocation: 'info.profile_url' }
      facebook        : {nicename: 'Facebook', urlLocation: 'link'             }
      github          : {nicename: 'GitHub'  , urlLocation: 'html_url'         }

      # END: PROPERTIES SHARED WITH BROWSER #


  #--- RUNTIME CONFIGURATION: WORKERS AND KITES ---#
  GOBIN = "#{projectRoot}/go/bin"


  # THESE COMMANDS WILL EXECUTE SEQUENTIALLY.

  KONFIG.workers =

    broker              : command : "#{GOBIN}/broker    -c #{configName}"
    rerouting           : command : "#{GOBIN}/rerouting -c #{configName}"
    cron                : command : "#{GOBIN}/cron      -c #{configName}"
    kloud               : command : "#{GOBIN}/kloud     -c #{configName} -env prod -r #{region} -port #{KONFIG.kloud.port} -public-key #{KONFIG.kloud.publicKeyFile} -private-key #{KONFIG.kloud.privateKeyFile} -register-url https://koding.io/kloud"

    socialapi           : command : "#{GOBIN}/api                -c #{socialapi.configFilePath}"
    dailyemailnotifier  : command : "#{GOBIN}/dailyemailnotifier -c #{socialapi.configFilePath}"
    notification        : command : "#{GOBIN}/notification       -c #{socialapi.configFilePath}"
    popularpost         : command : "#{GOBIN}/popularpost        -c #{socialapi.configFilePath}"
    populartopic        : command : "#{GOBIN}/populartopic       -c #{socialapi.configFilePath}"
    pinnedpost          : command : "#{GOBIN}/pinnedpost         -c #{socialapi.configFilePath}"
    realtime            : command : "#{GOBIN}/realtime           -c #{socialapi.configFilePath}"
    sitemapfeeder       : command : "#{GOBIN}/sitemapfeeder      -c #{socialapi.configFilePath}"
    sitemapgenerator    : command : "#{GOBIN}/sitemapgenerator   -c #{socialapi.configFilePath}"
    emailnotifier       : command : "#{GOBIN}/emailnotifier      -c #{socialapi.configFilePath}"
    topicfeed           : command : "#{GOBIN}/topicfeed          -c #{socialapi.configFilePath}"
    trollmode           : command : "#{GOBIN}/trollmode          -c #{socialapi.configFilePath}"

    appsproxy           : command : "node   #{projectRoot}/servers/appsproxy/web.js               -c #{configName} -p #{KONFIG.appsproxy.port}"
    authworker          : command : "coffee #{projectRoot}/workers/auth/lib/auth/main.coffee      -c #{configName}"
    socialworker        : command : "coffee #{projectRoot}/workers/social/lib/social/main.coffee  -c #{configName} -p #{KONFIG.social.port}      -r #{region} --disable-newrelic --kite-port=13020"
    sourcemaps          : command : "coffee #{projectRoot}/servers/sourcemaps/main.coffee         -c #{configName} -p #{KONFIG.sourcemaps.port}"
    emailsender         : command : "coffee #{projectRoot}/workers/emailsender/main.coffee        -c #{configName}"
    webserver           : command : "coffee #{projectRoot}/servers/lib/server/index.coffee        -c #{configName} -p #{KONFIG.webserver.port}   --disable-newrelic"

    # these are unnecessary on production machines.
    # ------------------------------------------------------------------------------------------
    # clientWatcher       : command : "coffee #{projectRoot}/build-client.coffee    --watch --sourceMapsUri #{hostname}"
    # reverseProxy        : command : "#{GOBIN}/rerun koding/kites/reverseproxy -port 1234 -env production -region #{publicHostname}PublicEnvironment -publicHost proxy-#{publicHostname}.ngrok.com -publicPort 80"
    # kloud               : command : "#{GOBIN}/rerun koding/kites/kloud     -c #{configName} -r #{region} -port #{KONFIG.kloud.port} -public-key #{KONFIG.kloud.publicKeyFile} -private-key #{KONFIG.kloud.privateKeyFile} -kontrol-url \"http://#{KONFIG.kloud.kontrolUrl}\" -debug"
    # kontrol             : command : "#{GOBIN}/rerun koding/kites/kontrol   -c #{configName} -r #{region}"
    # boxproxy            : command : "node   #{projectRoot}/servers/boxproxy/boxproxy.js           -c #{configName}"
    # ngrokProxy          : command : "#{projectRoot}/ngrokProxy --user #{publicHostname}"
    # --port #{kontrol.port} -env #{environment} -public-key #{kontrol.publicKeyFile} -private-key #{kontrol.privateKeyFile}"
    # guestcleaner        : command : "node #{projectRoot}/workers/guestcleaner/index.js     -c #{configName}"
    # ------------------------------------------------------------------------------------------






  #-------------------------------------------------------------------------#
  #---- SECTION: AUTO GENERATED CONFIGURATION FILES ------------------------#
  #---- DO NOT CHANGE ANYTHING BELOW. IT'S GENERATED FROM WHAT'S ABOVE  ----#
  #-------------------------------------------------------------------------#

  KONFIG.JSON = JSON.stringify KONFIG

  b64z = (str,strict=yes,compress=yes)->
    if str
      _b64 = new Buffer(str)
      _b64 = zlib.compress _b64 if compress
      # log "[b64z] before #{str.length} after #{_b64.length}"
      return _b64.toString('base64')
    else
      if strict
        throw "base64 STRING is empty, check main.#{configName}.coffee. this will break the prod machine, exiting."
      else
        return ""

  prodKeys =
    id_rsa     : fs.readFileSync("./install/keys/id_rsa","utf8")
    id_rsa_pub : fs.readFileSync("./install/keys/id_rsa.pub","utf8")


  nginxConf = """
    upstream webs      { server 127.0.0.1:#{KONFIG.webserver.port} ;}
    upstream social    { server 127.0.0.1:#{KONFIG.social.port}    ;}
    upstream subscribe { server 127.0.0.1:#{KONFIG.broker.port}    ;}
    upstream kloud     { server 127.0.0.1:#{KONFIG.kloud.port}     ;}
    upstream appsproxy { server 127.0.0.1:#{KONFIG.appsproxy.port} ;}
    upstream kontrol     {server 127.0.0.1:#{kontrol.port};}

    map $http_upgrade $connection_upgrade { default upgrade; '' close; }

    # TBD ssl_config

    server {
      listen 80 default_server;
      listen [::]:80 default_server ipv6only=on;
      listen 443;

      root /usr/share/nginx/html;
      index index.html index.htm;

      # Make site accessible from http://localhost/
      server_name localhost;


      server_name #{hostname};
      location / {
        proxy_pass            http://webs;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /xhr {
        proxy_pass            http://social;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /appsproxy {
        proxy_pass            http://appsproxy;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }


      location /kloud {
        proxy_pass            http://kloud;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /kontrol {
        proxy_pass            http://kontrol;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }


      # TBD. ADD WEBSOCKET SUPPORT HERE

      location ~^/subscribe/.* {
        proxy_pass http://subscribe;

        proxy_http_version 1.1;
        proxy_set_header      Upgrade    $http_upgrade;
        proxy_set_header      Connection "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location /websocket {
        proxy_pass http://subscribe;

        proxy_http_version 1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout invalid_header http_500;
        proxy_connect_timeout 1;
      }
    }
  """

  generateEnvVariables = (KONFIG)->
    conf = {}
    travis = traverse(KONFIG)
    travis.paths().forEach (path) -> conf["KONFIG_#{path.join("_")}".toUpperCase()] = travis.get(path) unless typeof travis.get(path) is 'object'
    return conf


  generateSupervisorConf = (KONFIG)->
    supervisorEnvironmentStr = "HOME='/root',GOPATH='#{projectRoot}/go',GOBIN='#{projectRoot}/go/bin',KONFIG_JSON='#{KONFIG.JSON}'"
    # supervisorEnvironmentStr += "#{key}='#{val}'," for key,val of KONFIG.ENV
    conf = """
      [supervisord]
      environment=#{supervisorEnvironmentStr}\n"""
      # """[inet_http_server]
      # port=localhost:9001\n\n"""
    conf +="""
      [program:#{key}]
      command=#{val.command}\n
    """ for key,val of KONFIG.workers
    return conf

  generateRunFile = (KONFIG) ->
    envvars = ->
      env = """
      export GOPATH=#{projectRoot}/go
      export GOBIN=#{projectRoot}/go/bin
      export HOME=/root
      export KONFIG_JSON='#{KONFIG.JSON}'
      \n
      """
      # env += "export #{key}='#{val}'\n" for key,val of KONFIG.ENV
      return env

    workersRunList = ->
      workers = ""
      for key,val of KONFIG.workers
        workers +="#------------- worker: #{key} -------------#\n"
        workers +="#{val.command} &>#{projectRoot}/.logs/#{key}.log & \n"
        workers +="#{key}pid=$! \n"
        workers +="echo [#{key}] started with pid: $#{key}pid \n\n"
      return workers


    runContents = """
      #!/bin/bash

      function install() {
        touch /root/run.install.start
        cd /opt
        git clone --branch '#{tag}' --depth 1 git@github.com:koding/koding.git koding

        cd /opt/koding

        # retrieve machine settings from the git tag namely, write nginx and supervisor conf.
        ms=`git tag -l -n1 | grep '#{tag}'`
        ms=${ms##*machine-settings-b64-zip-}  # get the part after the last separator
        echo $ms | base64 --decode | gunzip > #{projectRoot}/machineSettings
        bash #{projectRoot}/machineSettings

        git submodule init
        git submodule update --recursive
        npm i gulp stylus coffee-script -g
        npm i --unsafe-perm
        /usr/local/bin/coffee /opt/koding/build-client.coffee --watch false
        bash #{projectRoot}/go/build.sh
        cd #{projectRoot}/go/src/socialapi
        make install
        cd #{projectRoot}/node_modules_koding/koding-broker-client
        cake build
        mkdir $HOME/.kite
        echo copying #{KONFIG.newkites.keyFile} to $HOME/.kite/kite.key
        cp #{KONFIG.newkites.keyFile} $HOME/.kite/kite.key
        touch /root/run.install.end
      }

      function services() {
        touch /root/run.services.start
        cd #{projectRoot}/install/docker-mongo
        docker build -t koding_localbuild/mongo .
        docker run -d -p 27017:27017              --name=mongo    koding_localbuild/mongo --dbpath /data/db --smallfiles --nojournal
        docker run -d -p 5672:5672 -p 15672:15672 --name=rabbitmq koding/rabbitmq
        node #{projectRoot}/scripts/permission-updater  -c #{configName} --hard >/dev/null
        mongo #{mongo} --eval='db.jAccounts.update({},{$unset:{socialApiId:0}},{multi:true}); db.jGroups.update({},{$unset:{socialApiChannelId:0}},{multi:true});'
        service nginx restart
        service supervisor restart
        touch /root/run.services.end
        echo 'deploy finished.'
      }

      if [[ "$1" == "" ]]; then
        install
        services
        exit 0
      elif [ "$1" == "install" ]; then
        install
      elif [ "$1" == "services" ]; then
        services
      else
        echo "unknown argument."
      fi
      """


    run = """
      #/bin/bash
      touch /root/ididrun
      echo '#{b64z runContents}' | base64 --decode | gunzip | bash &>/root/koding-init.log
    """
      # chmod 0755 /root/run
      # uptime &>/root/uptime
      # /root/run &>/var/log/koding-init.log

    # return run
      # writefiles:
      #   - content     : !!binary |
      #       #{zlib.compress(new Buffer(runContents))}
      #     encoding    : gzip
      #     owner       : root:root
      #     path        : /root/run
      #     permissions : '0755'

    run = """
      #cloud-config

      # this file cannot exceed 16k therefore, i'm placing supervisor and nginxConf
      # into git tag message and reading it from there.
      # tl;dr - keep this small.

      disable_root: false
      hostname : #{hostname}

      packages:
        - mc
        - mosh
        - supervisor
        - golang
        - nodejs
        - npm
        - git
        - graphicsmagick
        - mosh
        - nginx

      write_files:
        - content : hello world
          path : /root/helloworld
        - path : /root/.ssh/id_rsa
          permissions: '0600'
          content : |
            #{prodKeys.id_rsa}

        - path : /root/.ssh/id_rsa.pub
          content : #{prodKeys.id_rsa_pub}

        - path : /root/.ssh/authorized_keys
          content : ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGy37UYYQjRUyBZ1gYERhmOcyRyF0pFvlc+d91VT6iiIituaR+SpGruyj3NSmTZQ8Px8/ebaIJQaV+8v/YyIJXAQoCo2voo/OO2WhVIzv2HUfyzXcomzV40sd8mqZJnNCQYdxkFbUZv26kOzikie0DlCoVstM9P8XAURSszO0llD4f0CKS7Galwql0plccBxJEK9oNWCMp3F6v3EIX6qdL8eUJko7tJDPiyPIuuaixxd4EBE/l2UBGvqG0REoDrBNJ8maKV3CKhw60LYis8EfKFhQg5055doDNxKSDiCMopXrfoiAQKEJ92MBTjs7YwuUDp5s39THbX9bHoyanbVIL devrim@koding.com\n

        - path : /root/.ssh/config
          content : |
            Host github.com
              StrictHostKeyChecking no

        - path: /root/run.b64z
          content : #{b64z runContents}
        - path: /root/run
          permissions: '0755'

        - path: /root/.dockercfg
          content: {"https://index.docker.io/v1/":{"auth":"ZGV2cmltOm45czQvV2UuTWRqZWNq","email":"devrim@koding.com"}}

      runcmd:
        - curl http://169.254.169.254/latest/meta-data/instance-id >/root/instance-id
        - ln -sf /usr/bin/nodejs /usr/bin/node
        - ln -sf /usr/bin/supervisorctl /usr/bin/s
        - cat /root/run.b64z | base64 --decode | gunzip > /root/run
        - /root/run
        - echo "deploy done."



    """
      # package_update: true
        # - echo '127.0.0.1 #{hostname}'                                      >> /etc/hosts
        # - echo #{hostname}                                                  >/etc/hostname
        # - hostname #{hostname}
        # - echo '#{b64z prodPrivateKey}'          | base64 --decode | gunzip > /root/.ssh/id_rsa
        # - echo '#{b64z prodPublicKey}'           | base64 --decode | gunzip > /root/.ssh/id_rsa
        # - echo '#{b64z authorized_keys}'         | base64 --decode | gunzip >> /root/.ssh/authorized_keys
        # - echo "Host github.com\n  StrictHostKeyChecking no"                >> /root/.ssh/config
        # - cp /usr/bin/nodejs /usr/bin/node
        # - ln -sf /usr/bin/supervisorctl /usr/bin/s
        # - mosh-server
        # - chmod 0755 /root/run
        # - /root/run

    return run

  cloudformation = ->
    return
        AWSTemplateFormatVersion: "2010-09-09"
        Description: "Koding deployment on AWS"
        Resources:
            KodingAutoScale:
                Type: "AWS::AutoScaling::AutoScalingGroup"
                Properties:
                    AvailabilityZones: ["us-east-1a"]
                    LaunchConfigurationName: {Ref: "KodingLaunchConfig"}
                    VPCZoneIdentifier: ["subnet-b47692ed"]
                    LoadBalancerNames: ["koding-prod-deployment"]
                    MinSize: "3"
                    MaxSize: "12"
                    DesiredCapacity: "3"
                    Tags: [ Key: "Name", Value: {Ref: "AWS::StackName"}, PropagateAtLaunch: yes]

            KodingLaunchConfig:
                Type: "AWS::AutoScaling::LaunchConfiguration"
                Properties:
                    ImageId: "ami-864d84ee"
                    InstanceType: "t2.micro"
                    KeyName: "koding-prod-deployment"
                    SecurityGroups: ["sg-64126d01"]
                    UserData: "Fn::Base64": run




  machineSettings = """
        \n
        echo '#{b64z nginxConf}'                      | base64 --decode | gunzip >  /etc/nginx/sites-enabled/default;
        echo "nginx configured."
        echo '#{b64z generateSupervisorConf(KONFIG)}' | base64 --decode | gunzip >  /etc/supervisor/conf.d/koding.conf;
        echo "supervisor configured."
  """


  KONFIG.machineSettings = b64z machineSettings
  KONFIG.runFile         = generateRunFile KONFIG

  return KONFIG


module.exports = Configuration
