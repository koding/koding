config  = require './config'
api     = require './api'

{argv} = require 'optimist'
KODING = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Databases Kite #{process.pid}"
  stats_id: "kite.databases." + process.pid
  interval : 30000
  librato: KODING.librato

api.run config
console.log "databases kite just restarted"






###
databasesKites = require './databasesKites'
KiteServer         = require 'kiteserver'



config =
  name     : "databases"
  portRange     : [4505,4600]
  kiteApi       : databasesKites
  pidFile       :
    path      :  '/var/run/node/Databases.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()
