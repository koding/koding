globals = require 'globals'

module.exports = (name) ->
  globals.appClasses[name]?.options?.version or null
