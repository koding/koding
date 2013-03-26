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