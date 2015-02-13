globals = require 'globals'

module.exports = (name) ->
  (globals.config.permissions.indexOf name) >= 0
