globals = require 'globals'

module.exports = (name) ->
  globals.appClasses[name]?.options or null
