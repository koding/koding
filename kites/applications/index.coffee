config  = require './config'
api     = require './api'

{argv} = require 'optimist'
KODING = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Applications Kite #{process.pid}"
  stats_id: "kite.applications." + process.pid
  interval : 30000
  librato: KODING.librato

api.run config
console.log "applications kite #{process.pid} is running"

module.exports = api
