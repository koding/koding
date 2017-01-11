traverse              = require 'traverse'
os                    = require 'os'

module.exports = (KONFIG, options, credentials) ->
  GOBIN = "%(ENV_KONFIG_PROJECTROOT)s/go/bin"
  GOPATH = "%(ENV_KONFIG_PROJECTROOT)s/go"

  workers =
    bucketproxies       :
      group             : "bucket"
      nginx             :
        s3bucket        : yes
        locations       : [
          {
            location    : '@assets'
            proxyPass   : 'http://s3.amazonaws.com/koding-assets$uri'
          }
          {
            location    : '~^/cdn/(koding-client|koding-assets|kodingdev-client|kodingdev-assets)/(.*)'
            proxyPass   : 'http://s3.amazonaws.com/$1/$2'
          }
          { # redirect /d/* to koding-dl S3 bucket; used to distributed kd/klient installers
            location    : '~^/d/(.*)$'
            proxyPass   : 'https://s3.amazonaws.com/koding-dl/$1'
          }
          { # redirect /d/kd to KD installer for development channel
            location    : '/c/d/kd'
            proxyPass   : 'https://s3.amazonaws.com/koding-kd/development/install-kd.sh'
          }
          { # redirect /p/kd to KD installer for production channel
            location    : '/c/p/kd'
            proxyPass   : 'https://s3.amazonaws.com/koding-kd/production/install-kd.sh'
          }
        ]

    assets              :
      group             : "static"
      nginx             :
        static          : yes
        locations       : [
          {
            location      : '/a/'
            proxyPass     : '$uri @assets'
            relativePath  : '/website/'
            expires       : '1M' # set -1 to disable.
            extraParamsStr: 'location ~* \.(map)$ { return 404; access_log off; }'
          }
          {
            location    : '/apidocs'
            proxyPass   : '$uri $uri/ /$uri $uri/index.html /$uri/index.html @assets'
            relativePath: '/website'
            expires     : '-1'
          }
          {
            location    : '~ ^/apidocs(.*)'
            proxyPass   : '$1 $1/ /$1 $1/index.html /$1/index.html $uri $uri/ /$uri $uri/index.html @assets'
            relativePath: '/website'
            expires     : '-1'
          }
          {
            location    : '/swagger.json'
            proxyPass   : '$uri @assets'
            relativePath: '/website/'
            expires     : '-1'
          }
        ]

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
        locations       : [
          { location: "/xhr"  }
          { location: "/remote.api" }
        ]
      healthCheckURL    : "http://localhost:#{KONFIG.social.port}/healthCheck"
      versionURL        : "http://localhost:#{KONFIG.social.port}/version"

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
            location    : "~ /api/social/account/channels"
            proxyPass   : "http://socialapi/account/channels$is_args$args"
          }
          {
            location    : "~ /api/social/payment/(.*)"
            proxyPass   : "http://socialapi/payment/$1$is_args$args"
          }
          {
            location    : "~ /api/social/presence/(.*)"
            proxyPass   : "http://socialapi/presence/$1$is_args$args"
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
        ]

    algoliaconnector    :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/algoliaconnector"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/algoliaconnector -watch socialapi/workers/algoliaconnector"

    realtime            :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/realtime"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/realtime -watch socialapi/workers/realtime"

    presence            :
      group             : "socialapi"
      supervisord       :
        command         :
          run           : "#{GOBIN}/presence"
          watch         : "#{GOBIN}/watcher -run socialapi/workers/cmd/presence -watch socialapi/workers/presence"

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
