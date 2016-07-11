kd = require 'kd'
globals = require 'globals'

KODING_INTERCOM_KEY = 'dv95y0rs'

module.exports = fetchIntercomKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team = groupsController.getCurrentGroup()

    intercomId = if groupsController.canEditGroup()
    then KODING_INTERCOM_KEY
    else team.customize?.intercomId

    callback intercomId
