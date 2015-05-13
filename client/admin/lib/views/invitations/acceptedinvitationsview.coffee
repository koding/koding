kd                     = require 'kd'
KDView                 = kd.View
PendingInvitationsView = require './pendinginvitationsview'


module.exports = class AcceptedInvitationsView extends PendingInvitationsView

  constructor: (options = {}, data) ->

    options.statusType = 'accepted'

    super options, data

