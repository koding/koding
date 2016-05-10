traverse              = require 'traverse'
os                    = require 'os'

module.exports = (KONFIG, options, credentials) ->
  GOBIN = "#{options.projectRoot}/go/bin"
  GOPATH = "#{options.projectRoot}/go"

  workers =
    gowebserver         :
      group             : "webserver"
      ports             :
        incoming       : "#{KONFIG.gowebserver.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/go-webserver -c #{options.configName}"
          watch         : "#{GOBIN}/watcher -run koding/go-webserver -c #{options.configName}"
      nginx             :
        locations       : [
          location      : "~^/IDE/.*"
      ]

      healthCheckURL    : "http://localhost:#{KONFIG.gowebserver.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.gowebserver.port}/version"

    kontrol             :
      group             : "environment"
      ports             :
        incoming        : "#{KONFIG.kontrol.port}"
      supervisord       :
        command         : "#{GOBIN}/kontrol -region #{options.region} -environment #{options.environment} -mongourl #{KONFIG.mongo} -port #{KONFIG.kontrol.port} -privatekey #{KONFIG.kontrol.privateKeyFile} -publickey #{KONFIG.kontrol.publicKeyFile} -storage postgres -postgres-dbname #{credentials.kontrolPostgres.dbname} -postgres-host #{credentials.kontrolPostgres.host} -postgres-port #{credentials.kontrolPostgres.port} -postgres-username #{credentials.kontrolPostgres.username} -postgres-password #{credentials.kontrolPostgres.password} -postgres-connecttimeout #{credentials.kontrolPostgres.connecttimeout}"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~^/kontrol/(.*)"
            proxyPass   : "http://kontrol/$1$is_args$args"
          }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.kontrol.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kontrol.port}/version"

    kloud               :
      group             : "environment"
      ports             :
        incoming        : "#{KONFIG.kloud.port}"
      supervisord       :
        command         : "#{GOBIN}/kloud -networkusageendpoint http://localhost:#{KONFIG.vmwatcher.port} -planendpoint #{KONFIG.socialapi.proxyUrl}/payments/subscriptions -credentialendpoint #{KONFIG.socialapi.proxyUrl}/credential -hostedzone #{options.userSitesDomain} -region #{options.region} -environment #{options.environment} -port #{KONFIG.kloud.port}  -userprivatekey #{KONFIG.kloud.userPrivateKeyFile} -userpublickey #{KONFIG.kloud.userPublicKeyfile}  -publickey #{KONFIG.kontrol.publicKeyFile} -privatekey #{KONFIG.kontrol.privateKeyFile} -kontrolurl #{KONFIG.kontrol.url}  -registerurl #{KONFIG.kloud.registerUrl} -mongourl #{KONFIG.mongo} -prodmode=#{options.configName is "prod"} -awsaccesskeyid=#{credentials.awsKeys.vm_kloud.accessKeyId} -awssecretaccesskey=#{credentials.awsKeys.vm_kloud.secretAccessKey} -slusername=#{credentials.slKeys.vm_kloud.username} -slapikey=#{credentials.slKeys.vm_kloud.apiKey} -janitorsecretkey=#{KONFIG.socialapi.janitor.secretKey} -vmwatchersecretkey=#{KONFIG.vmwatcher.secretKey} -paymentwebhooksecretkey=#{KONFIG.paymentwebhook.secretKey} -kloudsecretkey=#{credentials.kloud.secretKey} -tunnelurl #{KONFIG.kloud.tunnelUrl}"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~^/kloud/(.*)"
            proxyPass   : "http://kloud/$1$is_args$args"
          }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.kloud.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.kloud.port}/version"

    terraformer         :
      group             : "environment"
      supervisord       :
        command         : "#{GOBIN}/terraformer -port #{KONFIG.terraformer.port} -region #{options.region} -environment  #{options.environment} -aws-key #{credentials.awsKeys.worker_terraformer.accessKeyId} -aws-secret #{credentials.awsKeys.worker_terraformer.secretAccessKey} -aws-bucket #{KONFIG.terraformer.bucket} -localstorepath #{KONFIG.terraformer.localstorepath}"
      healthCheckURL    : "http://localhost:#{KONFIG.terraformer.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.terraformer.port}/version"

    broker              :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.broker.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/broker -c #{options.configName}"
          watch         : "#{GOBIN}/watcher -run koding/broker -c #{options.configName}"
      nginx             :
        websocket       : yes
        locations       : [
          { location    : "/websocket" }
          { location    : "~^/subscribe/.*" }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.broker.port}/info"
      versionURL        : "http://localhost:#{KONFIG.broker.port}/version"

    rerouting           :
      group             : "webserver"
      supervisord       :
        command         :
          run           : "#{GOBIN}/rerouting -c #{options.configName}"
          watch         : "#{GOBIN}/watcher -run koding/rerouting -c #{options.configName}"
      healthCheckURL    : "http://localhost:#{KONFIG.rerouting.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.rerouting.port}/version"

    authworker          :
      group             : "webserver"
      supervisord       :
        command         : "./watch-node #{options.projectRoot}/workers/auth/index.js -c #{options.configName} -p #{KONFIG.authWorker.port}"
      healthCheckURL    : "http://localhost:#{KONFIG.authWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.authWorker.port}/version"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      nginx             :
        locations       : [ { location : "/sourcemaps" } ]
      supervisord       :
        command         : "./watch-node #{options.projectRoot}/servers/sourcemaps/index.js -c #{options.configName} -p #{KONFIG.sourcemaps.port}"

    webserver           :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.webserver.port}"
        outgoing        : "#{KONFIG.webserver.kitePort}"
      supervisord       :
        command         : "./watch-node #{options.projectRoot}/servers/index.js -c #{options.configName} -p #{KONFIG.webserver.port} --kite-port=#{KONFIG.webserver.kitePort} --kite-key=#{credentials.kiteHome}/kite.key"
      nginx             :
        locations       : [
          {
            location    : "~ /-/api/(.*)"
            proxyPass   : "http://webserver/-/api/$1$is_args$args"
          }
          {
            location    : "/"
          }
        ]

    socialworker        :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.social.port}"
        outgoing        : "#{KONFIG.social.kitePort}"
      supervisord       :
        command         : "./watch-node #{options.projectRoot}/workers/social/index.js -c #{options.configName} -p #{KONFIG.social.port} -r #{options.region} --kite-port=#{KONFIG.social.kitePort} --kite-key=#{credentials.kiteHome}/kite.key"
      nginx             :
        locations       : [ { location: "/xhr" } ]
      healthCheckURL    : "http://localhost:#{KONFIG.social.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.social.port}/version"

    paymentwebhook      :
      group             : "socialapi"
      ports             :
        incoming        : KONFIG.paymentwebhook.port
      supervisord       :
        stopwaitsecs    : 20
        command         :
          run           : "#{GOBIN}/paymentwebhook -c #{KONFIG.socialapi.configFilePath} -kite-init=true"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi paymentwebhookdev config=#{KONFIG.socialapi.configFilePath}"
      healthCheckURL    : "http://localhost:#{KONFIG.paymentwebhook.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.paymentwebhook.port}/version"
      nginx             :
        locations       : [
          { location    : "= /-/payments/stripe/webhook" },
        ]

    vmwatcher           :
      group             : "environment"
      instances         : 1
      ports             :
        incoming        : "#{KONFIG.vmwatcher.port}"
      supervisord       :
        stopwaitsecs    : 20
        command         :
          run           : "#{GOBIN}/vmwatcher -c #{options.configName}"
          watch         : "#{GOBIN}/watcher -run koding/vmwatcher"
      nginx             :
        locations       : [ { location: "/vmwatcher" } ]
      healthCheckURL    : "http://localhost:#{KONFIG.vmwatcher.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.vmwatcher.port}/version"

    socialapi:
      group             : "socialapi"
      instances         : 1
      ports             :
        incoming        : "#{KONFIG.socialapi.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/api -c #{KONFIG.socialapi.configFilePath} -port=#{KONFIG.socialapi.port}"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi apidev config=#{KONFIG.socialapi.configFilePath}"
      healthCheckURL    : "#{KONFIG.socialapi.proxyUrl}/healthCheck"
      versionURL        : "#{KONFIG.socialapi.proxyUrl}/version"
      nginx             :
        locations       : [
          # location ordering is important here. if you are going to need to change it or
          # add something new, thoroughly test it in sandbox. Most of the problems are not occuring
          # in dev environment
          {
            location    : "~ /api/social/channel/(.*)/history/count"
            proxyPass   : "http://socialapi/channel/$1/history/count$is_args$args"
          }
          {
            location    : "~ /api/social/channel/(.*)/history"
            proxyPass   : "http://socialapi/channel/$1/history$is_args$args"
          }
          {
            location    : "~ /api/social/channel/(.*)/list"
            proxyPass   : "http://socialapi/channel/$1/list$is_args$args"
          }
          {
            location    : "~ /api/social/channel/by/(.*)"
            proxyPass   : "http://socialapi/channel/by/$1$is_args$args"
          }
          {
            location    : "~ /api/social/channel/(.*)/notificationsetting"
            proxyPass   : "http://socialapi/channel/$1/notificationsetting$is_args$args"
          }
          {
            location    : "~ /api/social/notificationsetting/(.*)"
            proxyPass   : "http://socialapi/notificationsetting/$1$is_args$args"
          }
          {
            location    : "~ /api/social/collaboration/ping"
            proxyPass   : "http://socialapi/collaboration/ping$1$is_args$args"
          }
          {
            location    : "~ /api/social/search-key"
            proxyPass   : "http://socialapi/search-key$1$is_args$args"
          }
          {
            location    : "~ /api/social/sshkey"
            proxyPass   : "http://socialapi/sshkey$1$is_args$args"
          }
          {
            location    : "~ /api/social/moderation/(.*)"
            proxyPass   : "http://socialapi/moderation/$1$is_args$args"
          }
          {
            location    : "~ /api/social/account/channels"
            proxyPass   : "http://socialapi/account/channels$is_args$args"
          }
          {
            location    : "~* ^/api/social/slack/(.*)"
            proxyPass   : "http://socialapi/slack/$1$is_args$args"
            extraParams : [ "proxy_buffering off;" ] # appearently slack sends a big header
          }
          {
            location    : "~ /api/social/(.*)"
            proxyPass   : "http://socialapi/$1$is_args$args"
            internalOnly: yes
          }
          {
            location    : "~ /sitemap(.*).xml"
            proxyPass   : "http://socialapi/sitemap$1.xml"
          }

        ]

    dailyemailnotifier  :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/dailyemail -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/dailyemail -watch socialapi/workers/email/dailyemail -c #{KONFIG.socialapi.configFilePath}"

    algoliaconnector    :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/algoliaconnector -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/algoliaconnector -watch socialapi/workers/algoliaconnector -c #{KONFIG.socialapi.configFilePath}"

    notification        :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/notification -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/notification -watch socialapi/workers/notification -c #{KONFIG.socialapi.configFilePath}"

    popularpost         :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/popularpost -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/popularpost -watch socialapi/workers/popularpost -c #{KONFIG.socialapi.configFilePath}"

    populartopic        :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/populartopic -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/populartopic -watch socialapi/workers/populartopic -c #{KONFIG.socialapi.configFilePath}"

    pinnedpost          :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/pinnedpost -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/pinnedpost -watch socialapi/workers/pinnedpost -c #{KONFIG.socialapi.configFilePath}"

    realtime            :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/realtime -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/realtime -watch socialapi/workers/realtime -c #{KONFIG.socialapi.configFilePath}"

    sitemapfeeder       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/sitemapfeeder -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/sitemapfeeder -watch socialapi/workers/sitemapfeeder -c #{KONFIG.socialapi.configFilePath}"

    sitemapgenerator    :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/sitemapgenerator -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/sitemapgenerator -watch socialapi/workers/sitemapgenerator -c #{KONFIG.socialapi.configFilePath}"

    activityemail       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/activityemail -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/activityemail -watch socialapi/workers/email/activityemail -c #{KONFIG.socialapi.configFilePath}"

    topicfeed           :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/topicfeed -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/topicfeed -watch socialapi/workers/topicfeed -c #{KONFIG.socialapi.configFilePath}"

    trollmode           :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/trollmode -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/trollmode -watch socialapi/workers/trollmode -c #{KONFIG.socialapi.configFilePath}"

    privatemessageemailfeeder:
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/privatemessageemailfeeder -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/privatemessageemailfeeder -watch socialapi/workers/email/privatemessageemailfeeder -c #{KONFIG.socialapi.configFilePath}"

    privatemessageemailsender:
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/privatemessageemailsender -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/privatemessageemailsender -watch socialapi/workers/email/privatemessageemailsender -c #{KONFIG.socialapi.configFilePath}"

    topicmoderation     :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/topicmoderation -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/topicmoderation -watch socialapi/workers/topicmoderation -c #{KONFIG.socialapi.configFilePath}"

    collaboration       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/collaboration -c #{KONFIG.socialapi.configFilePath} -kite-init=true"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/collaboration -watch socialapi/workers/collaboration -c #{KONFIG.socialapi.configFilePath} -kite-init=true"

    gatekeeper          :
      group             : "socialapi"
      ports             :
        incoming        : "#{KONFIG.gatekeeper.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/gatekeeper -c #{KONFIG.socialapi.configFilePath}"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi gatekeeperdev config=#{KONFIG.socialapi.configFilePath}"
      healthCheckURL    : "#{options.customDomain.local}/api/gatekeeper/healthCheck"
      versionURL        : "#{options.customDomain.local}/api/gatekeeper/version"
      nginx             :
        locations       : [
          location      : "~ /api/gatekeeper/(.*)"
          proxyPass     : "http://gatekeeper/$1$is_args$args"
        ]

    dispatcher          :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/dispatcher -c #{KONFIG.socialapi.configFilePath}"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi dispatcherdev config=#{KONFIG.socialapi.configFilePath}"

    mailsender          :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/emailsender -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/emailsender -watch socialapi/workers/emailsender -c #{KONFIG.socialapi.configFilePath}"

    team                :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/team -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/team -watch socialapi/workers/team -c #{KONFIG.socialapi.configFilePath}"

    janitor             :
      group             : "environment"
      instances         : 1
      supervisord       :
        command         : "#{GOBIN}/janitor -c #{KONFIG.socialapi.configFilePath} -kite-init=true"
      healthCheckURL    : "http://localhost:#{KONFIG.socialapi.janitor.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.socialapi.janitor.port}/version"

    gatheringestor      :
      ports             :
        incoming        : KONFIG.gatheringestor.port
      group             : "environment"
      instances         : 1
      supervisord       :
        stopwaitsecs    : 20
        command         :
          run           : "#{GOBIN}/gatheringestor -c #{options.configName}"
          watch         : "#{GOBIN}/watcher -run koding/workers/gatheringestor -c #{options.configName}"
      healthCheckURL    : "http://localhost:#{KONFIG.gatheringestor.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.gatheringestor.port}/version"
      nginx             :
        locations       : [
          location      : "~ /-/ingestor/(.*)"
          proxyPass     : "http://gatheringestor/$1$is_args$args"
        ]

    integration         :
      group             : "socialapi"
      ports             :
        incoming        : "#{KONFIG.integration.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/webhook -c #{KONFIG.socialapi.configFilePath}"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi webhookdev config=#{KONFIG.socialapi.configFilePath}"
      healthCheckURL    : "#{options.customDomain.local}/api/integration/healthCheck"
      versionURL        : "#{options.customDomain.local}/api/integration/version"
      nginx             :
        locations       : [
          location      : "~ /api/integration/(.*)"
          proxyPass     : "http://integration/$1$is_args$args"
        ]

    webhook             :
      group             : "socialapi"
      ports             :
        incoming        : "#{KONFIG.socialapi.webhookMiddleware.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/webhookmiddleware -c #{KONFIG.socialapi.configFilePath}"
          watch         : "make -C #{options.projectRoot}/go/src/socialapi middlewaredev config=#{KONFIG.socialapi.configFilePath}"
      healthCheckURL    : "#{options.customDomain.local}/api/webhook/healthCheck"
      versionURL        : "#{options.customDomain.local}/api/webhook/version"
      nginx             :
        locations       : [
          location      : "~ /api/webhook/(.*)"
          proxyPass     : "http://webhook/$1$is_args$args"
        ]

    eventsender         :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/eventsender -c #{KONFIG.socialapi.configFilePath}"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/eventsender -watch socialapi/workers/eventsender -c #{KONFIG.socialapi.configFilePath}"

    contentrotator      :
      group             : "webserver"
      nginx             :
        locations       : [
          {
            location    : "~ /-/content-rotator/(.*)"
            proxyPass   : "#{KONFIG.contentRotatorUrl}/content-rotator/$1"
            extraParams : [ "resolver 8.8.8.8;" ]
          }
        ]

    tunnelproxymanager  :
      group             : "proxy"
      supervisord       :
        command         : "#{GOBIN}/tunnelproxymanager -ebenvname #{options.ebEnvName} -accesskeyid #{credentials.awsKeys.worker_tunnelproxymanager.accessKeyId} -secretaccesskey #{credentials.awsKeys.worker_tunnelproxymanager.secretAccessKey} -hostedzone-name devtunnelproxy.koding.com -hostedzone-callerreference devtunnelproxy_hosted_zone_v0"

    tunnelserver        :
      group             : "proxy"
      supervisord       :
        command         : "#{GOBIN}/tunnelserver -accesskey #{credentials.awsKeys.worker_tunnelproxymanager.accessKeyId} -secretkey #{credentials.awsKeys.worker_tunnelproxymanager.secretAccessKey} -port #{KONFIG.tunnelserver.port} -basevirtualhost #{KONFIG.tunnelserver.basevirtualhost} -hostedzone #{KONFIG.tunnelserver.hostedzone} -region #{options.region} -environment #{options.environment}"
      ports             :
        incoming        : "#{KONFIG.tunnelserver.port}"
      healthCheckURL    : "http://tunnelserver/healthCheck"
      versionURL        : "http://tunnelserver/version"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : "~ /tunnelserver/(.*)"
            proxyPass   : "http://tunnelserver/$1"
          }
        ]

    userproxies         :
      group             : "proxy"
      nginx             :
        websocket       : yes
        locations       : [
          {
            location    : '~ ^\\/-\\/prodproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : '~ ^\\/-\\/devproxy\\/(?<ip>.+?)\\/(?<rest>.*)'
            proxyPass   : 'http://$ip:56789/$rest'
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
            ]
          }
          {
            location    : "~ ^\\/-\\/prodtunnel\\/(?<tunnel>.+?)\.#{KONFIG.tunnelserver.hostedzone}(?<rest>.*)"
            proxyPass   : "http://$tunnel.#{KONFIG.tunnelserver.hostedzone}$rest"
            host        : "$tunnel.#{KONFIG.tunnelserver.hostedzone}"
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
              'resolver 8.8.8.8;'
            ]
          }
          {
            location    : "~ ^\\/-\\/devtunnel\\/(?<tunnel>.+?)\.#{KONFIG.tunnelserver.hostedzone}(?<rest>.*)"
            proxyPass   : "http://$tunnel.#{KONFIG.tunnelserver.hostedzone}$rest"
            host        : "$tunnel.#{KONFIG.tunnelserver.hostedzone}"
            extraParams : [
              'proxy_read_timeout 21600s;'
              'proxy_send_timeout 21600s;'
              'resolver 8.8.8.8;'
            ]
          }
        ]
