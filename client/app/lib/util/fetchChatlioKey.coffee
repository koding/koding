kd = require 'kd'
globals = require 'globals'

module.exports = fetchChatlioKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team = groupsController.getCurrentGroup()
    chatlioId = team.customize?.chatlioId

    return callback no  unless chatlioId

    callback chatlioId, isAdmin
