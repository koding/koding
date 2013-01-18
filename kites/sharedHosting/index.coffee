config  = require './config'
api     = require './api'

api.run config
console.log "shared hosting just restarted"

{argv} = require 'optimist'
KODING = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Shared Hosting Kite #{process.pid}"
  stats_id: "kite.sharedhosting." + process.pid
  interval : 30000
  librato: KODING.librato

api.on 'error', console.error

module.exports = api
