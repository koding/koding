config  = require './config'
api     = require './api'

api.run config
console.log "shared hosting just restarted"

module.exports = api
