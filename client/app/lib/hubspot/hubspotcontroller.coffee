kd           = require 'kd'
KDController = kd.Controller
whoami       = require 'app/util/whoami'

module.exports = class HubspotTracker extends KDController

  track: (action) ->

    return unless action

    account = whoami()
    account.fetchEmail (err, email) ->

      analytics.track
        userId     : whoami().getId()
        event      : "#{action}"
        properties :
          email : email
