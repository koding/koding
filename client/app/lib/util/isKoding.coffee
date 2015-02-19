globals = require 'globals'

module.exports = ->
  return globals.config.entryPoint?.slug is 'koding'
