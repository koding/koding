{argv}  = require 'optimist'

api     = require './api'
config  = require './'+ argv.c ? 'config'

api.run config