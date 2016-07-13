kd = require 'kd'
globals = require 'globals'

module.exports = fetchIntercomKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team = groupsController.getCurrentGroup()

    intercomAppId = if groupsController.canEditGroup()
    then globals.config.intercomAppId
    else team.customize?.intercomAppId

    callback intercomAppId
