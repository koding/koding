config  = require './config'
api     = require './api'

api.run config
console.log "applications kite #{process.pid} is running"

module.exports = api
