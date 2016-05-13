kd = require 'kd'
globals = require 'globals'
KODING_CHATLIO_KEY = 'ae02da65-1664-4e7b-49c8-31abedbb80ed'

module.exports = fetchChatlioKey = (callback = noop) ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    isAdmin   = no
    team      = groupsController.getCurrentGroup()
    chatlioId = team.customize?.chatlioId
    { roles } = globals.config

    # if user is an admin or owner
    # their support requests should
    # come to koding support not to
    # their own slack that they set up
    if ('admin' in roles) or ('owner' in roles)
      chatlioId = KODING_CHATLIO_KEY
      isAdmin   = yes

    callback no  unless chatlioId

    callback chatlioId, isAdmin
