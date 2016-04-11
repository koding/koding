kd                     = require 'kd'
KDCustomHTMLView       = kd.CustomHTMLView
PendingInvitationsView = require './pendinginvitationsview'


module.exports = class AcceptedInvitationsView extends PendingInvitationsView

  constructor: (options = {}, data) ->

    options.statusType          = 'accepted'
    options.listViewItemOptions = { statusType: 'accepted' }
    options.noItemFoundText     = 'There is no accepted invitation.'

    super options, data
