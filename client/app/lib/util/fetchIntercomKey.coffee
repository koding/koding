kd = require 'kd'
globals = require 'globals'

module.exports = fetchIntercomKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team = groupsController.getCurrentGroup()

    intercomAppId = team.customize?.intercomAppId

    callback intercomAppId
