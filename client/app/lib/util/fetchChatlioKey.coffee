kd = require 'kd'
globals = require 'globals'
KODING_CHATLIO_KEY = 'ae02da65-1664-4e7b-49c8-31abedbb80ed'

module.exports = fetchChatlioKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team = groupsController.getCurrentGroup()
    chatlioId = team.customize?.chatlioId
    if isAdmin = groupsController.canEditGroup()
      chatlioId = KODING_CHATLIO_KEY

    return callback no  unless chatlioId

    callback chatlioId, isAdmin
