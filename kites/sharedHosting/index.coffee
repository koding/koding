{argv}  = require 'optimist'

config  = require './' + argv.c ? 'config'
api     = require './api'

api.run config
console.log "shared hosting just restarted"
