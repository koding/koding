globals = require 'globals'

module.exports = ->

  return globals.config.entryPoint?.type is 'group'
