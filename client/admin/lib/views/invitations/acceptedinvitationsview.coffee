kd                     = require 'kd'
KDCustomHTMLView       = kd.CustomHTMLView
PendingInvitationsView = require './pendinginvitationsview'


module.exports = class AcceptedInvitationsView extends PendingInvitationsView

  constructor: (options = {}, data) ->

    options.statusType                  or= 'accepted'
    options.listViewItemOptions         or= { statusType: 'accepted' }
    options.noItemFoundText             or= 'There is no accepted invitation.'
    options.useCustomThresholdHandler    ?= no

    super options, data
