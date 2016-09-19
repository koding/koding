traverse              = require 'traverse'
os                    = require 'os'

module.exports = (KONFIG, options, credentials) ->
  GOBIN = "%(ENV_KONFIG_PROJECTROOT)s/go/bin"
  GOPATH = "%(ENV_KONFIG_PROJECTROOT)s/go"

  workers =
    gowebserver         :
      group             : "webserver"
      ports             :
        incoming       : "#{KONFIG.gowebserver.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/go-webserver"
          watch         : "#{GOBIN}/watcher -run koding/go-webserver"
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
        command         : "#{GOBIN}/kontrol"
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
        command         : "#{GOBIN}/kloud"
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
        command         : "#{GOBIN}/terraformer"
      healthCheckURL    : "http://localhost:#{KONFIG.terraformer.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.terraformer.port}/version"

    broker              :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.broker.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/broker"
          watch         : "#{GOBIN}/watcher -run koding/broker"
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
          run           : "#{GOBIN}/rerouting"
          watch         : "#{GOBIN}/watcher -run koding/rerouting"
      healthCheckURL    : "http://localhost:#{KONFIG.rerouting.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.rerouting.port}/version"

    authworker          :
      group             : "webserver"
      supervisord       :
        command         : "./watch-node %(ENV_KONFIG_PROJECTROOT)s/workers/auth/index.js"
      healthCheckURL    : "http://localhost:#{KONFIG.authWorker.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.authWorker.port}/version"

    sourcemaps          :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.sourcemaps.port}"
      nginx             :
        locations       : [ { location : "/sourcemaps" } ]
      supervisord       :
        command         : "./watch-node %(ENV_KONFIG_PROJECTROOT)s/servers/sourcemaps/index.js"

    webserver           :
      group             : "webserver"
      ports             :
        incoming        : "#{KONFIG.webserver.port}"
        outgoing        : "#{KONFIG.webserver.kitePort}"
      supervisord       :
        command         : "./watch-node %(ENV_KONFIG_PROJECTROOT)s/servers/index.js"
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
        command         : "./watch-node %(ENV_KONFIG_PROJECTROOT)s/workers/social/index.js"
      nginx             :
        locations       : [ { location: "/xhr" } ]
      healthCheckURL    : "http://localhost:#{KONFIG.social.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.social.port}/version"

    vmwatcher           :
      group             : "environment"
      instances         : 1
      ports             :
        incoming        : "#{KONFIG.vmwatcher.port}"
      supervisord       :
        stopwaitsecs    : 20
        command         :
          run           : "#{GOBIN}/vmwatcher"
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
          run           : "#{GOBIN}/api -port=#{KONFIG.socialapi.port}"
          watch         : "make -C %(ENV_KONFIG_PROJECTROOT)s/go/src/socialapi apidev"
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
          run           : "#{GOBIN}/dailyemail"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/dailyemail -watch socialapi/workers/email/dailyemail"

    algoliaconnector    :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/algoliaconnector"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/algoliaconnector -watch socialapi/workers/algoliaconnector"

    notification        :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/notification"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/notification -watch socialapi/workers/notification"

    popularpost         :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/popularpost"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/popularpost -watch socialapi/workers/popularpost"

    populartopic        :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/populartopic"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/populartopic -watch socialapi/workers/populartopic"

    pinnedpost          :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/pinnedpost"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/pinnedpost -watch socialapi/workers/pinnedpost"

    realtime            :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/realtime"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/realtime -watch socialapi/workers/realtime"

    sitemapfeeder       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/sitemapfeeder"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/sitemapfeeder -watch socialapi/workers/sitemapfeeder"

    sitemapgenerator    :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/sitemapgenerator"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/sitemapgenerator -watch socialapi/workers/sitemapgenerator"

    activityemail       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/activityemail"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/activityemail -watch socialapi/workers/email/activityemail"

    topicfeed           :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/topicfeed"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/topicfeed -watch socialapi/workers/topicfeed"

    trollmode           :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/trollmode"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/trollmode -watch socialapi/workers/trollmode"

    privatemessageemailfeeder:
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/privatemessageemailfeeder"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/privatemessageemailfeeder -watch socialapi/workers/email/privatemessageemailfeeder"

    privatemessageemailsender:
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/privatemessageemailsender"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/email/privatemessageemailsender -watch socialapi/workers/email/privatemessageemailsender"

    topicmoderation     :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/topicmoderation"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/topicmoderation -watch socialapi/workers/topicmoderation"

    collaboration       :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/collaboration -kite-init=true"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/collaboration -watch socialapi/workers/collaboration -kite-init=true"

    gatekeeper          :
      group             : "socialapi"
      ports             :
        incoming        : "#{KONFIG.gatekeeper.port}"
      supervisord       :
        command         :
          run           : "#{GOBIN}/gatekeeper"
          watch         : "make -C %(ENV_KONFIG_PROJECTROOT)s/go/src/socialapi gatekeeperdev"
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
          run           : "#{GOBIN}/dispatcher"
          watch         : "make -C %(ENV_KONFIG_PROJECTROOT)s/go/src/socialapi dispatcherdev"

    mailsender          :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/emailsender"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/emailsender -watch socialapi/workers/emailsender"

    team                :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/team"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/team -watch socialapi/workers/team"

    janitor             :
      group             : "environment"
      instances         : 1
      supervisord       :
        command         : "#{GOBIN}/janitor -kite-init=true"
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
          run           : "#{GOBIN}/gatheringestor"
          watch         : "#{GOBIN}/watcher -run koding/workers/gatheringestor"
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
          run           : "#{GOBIN}/webhook"
          watch         : "make -C %(ENV_KONFIG_PROJECTROOT)s/go/src/socialapi webhookdev"
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
          run           : "#{GOBIN}/webhookmiddleware"
          watch         : "make -C %(ENV_KONFIG_PROJECTROOT)s/go/src/socialapi middlewaredev"
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
          run           : "#{GOBIN}/eventsender"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/eventsender -watch socialapi/workers/eventsender"

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
        command         : "#{GOBIN}/tunnelproxymanager"

    tunnelserver        :
      group             : "proxy"
      supervisord       :
        command         : "#{GOBIN}/tunnelserver"
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
