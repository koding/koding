kd                    = require 'kd'
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView


module.exports = class AdminInvitationsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    @addSubView @tabView   = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 210

    @tabView.addPane new KDTabPaneView name: 'Pending Invitations'
    @tabView.addPane new KDTabPaneView name: 'Accepted Invitations'

    @tabView.showPaneByIndex 0
