Bongo = require 'bongo'
Broker = require 'broker'
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

require 'colors'

broker = new Broker KONFIG.mq

koding = new Bongo
  root        : __dirname
  models      : '../workers/social/lib/social/models'
  resourceName: 'bongo-api-builder'

koding.on 'apiReady', ->
  koding.describeApi (api) ->
    source = "var REMOTE_API = #{ JSON.stringify api };"
    require('fs').writeFileSync argv.o, source, 'utf-8'
    process.exit()
