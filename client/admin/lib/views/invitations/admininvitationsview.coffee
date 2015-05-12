kd                      = require 'kd'
KDView                  = kd.View
KDTabView               = kd.TabView
KDTabPaneView           = kd.TabPaneView
PendingInvitationsView  = require './pendinginvitationsview'
AcceptedInvitationsView = require './acceptedinvitationsview'


module.exports = class AdminInvitationsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    @addSubView @tabView   = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 210

    @tabView.addPane pending  = new KDTabPaneView name: 'Pending Invitations'
    @tabView.addPane accepted = new KDTabPaneView name: 'Accepted Invitations'

    @tabView.showPaneByIndex 0

    pending.addSubView  new PendingInvitationsView  {}, @getData()
    accepted.addSubView new AcceptedInvitationsView {}, @getData()
