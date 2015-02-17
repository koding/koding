globals = require 'globals'

module.exports = (name) ->
  delete globals.appClasses[name]
