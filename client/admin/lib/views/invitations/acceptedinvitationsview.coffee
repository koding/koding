kd                     = require 'kd'
KDCustomHTMLView       = kd.CustomHTMLView
PendingInvitationsView = require './pendinginvitationsview'


module.exports = class AcceptedInvitationsView extends PendingInvitationsView

  constructor: (options = {}, data) ->

    options.statusType          = 'accepted'
    options.listViewItemOptions = statusType: 'accepted'
    options.noItemFoundWidget   = new KDCustomHTMLView
      partial  : 'There is no accepted invitation.'
      cssClass : 'hidden no-item-view'

    super options, data
