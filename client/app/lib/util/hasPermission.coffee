globals = require 'globals'

module.exports = (name) ->

  unless globals.config and globals.config.permissions
    console.warn '[hasPermission] must be called after reception of \'mainController.ready\' event'

    return no

  (globals.config.permissions.indexOf name) >= 0
