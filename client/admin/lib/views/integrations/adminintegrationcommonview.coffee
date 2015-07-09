kd           = require 'kd'
JView        = require 'app/jview'

module.exports = class AdminIntegrationCommonView extends JView

  constructor: (options = {}, data) ->

    path = kd.singletons.router.getCurrentPath()
    [ identifier, action ] = path.split('/').reverse()

    options.action     = action
    options.identifier = identifier

    super options, data
