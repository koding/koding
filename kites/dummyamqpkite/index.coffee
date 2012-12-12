require 'coffee-script'
api     = require './api'
config  = require './config'

console.log config

api.on 'error', console.error

api.run config