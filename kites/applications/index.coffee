config  = require './config'
api     = require './api'

api.run config
console.log "applications kite #{process.pid} is running"

{librato} = config
processMonitor = (require 'processes-monitor').start
  name : "Applications Kite #{process.pid}"
  stats_id: "kite.applications." + process.pid
  interval : 30000
  librato: librato

module.exports = api
