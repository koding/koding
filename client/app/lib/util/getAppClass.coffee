globals = require 'globals'

module.exports = (name) ->
  globals.appClasses[name]?.fn or null
