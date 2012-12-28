config  = require './config'
api     = require './api'

api.run config
console.log "shared hosting just restarted"

api.on 'error', console.error

module.exports = api
