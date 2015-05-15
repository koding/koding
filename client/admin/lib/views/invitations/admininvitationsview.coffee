kd                      = require 'kd'
KDView                  = kd.View
KDTabView               = kd.TabView
KDButtonView            = kd.ButtonView
KDTabPaneView           = kd.TabPaneView
InviteSomeoneView       = require './invitesomeoneview'
PendingInvitationsView  = require './pendinginvitationsview'
AcceptedInvitationsView = require './acceptedinvitationsview'


module.exports = class AdminInvitationsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()
    @createInviteButton()


  createTabView: ->

    data = @getData()

    @addSubView tabView = @tabView = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 210

    tabView.addPane pending  = new KDTabPaneView name: 'Pending Invitations'
    tabView.addPane accepted = new KDTabPaneView name: 'Accepted Invitations'
    tabView.addPane invite   = new KDTabPaneView name: 'Invite', hiddenHandle: yes

    pending.addSubView  pendingView  = new PendingInvitationsView  {}, data
    accepted.addSubView acceptedView = new AcceptedInvitationsView {}, data
    invite.addSubView   inviteView   = new InviteSomeoneView {}, data

    tabView.showPaneByIndex 0

    inviteView.on 'InvitationViewCancelled', =>
      tabView.showPaneByIndex tabView.lastOpenPaneIndex
      @inviteButton.show()

    tabView.on 'PaneDidShow', => @inviteButton.show()
    inviteView.on 'NewInvitationsAdded', => pendingView.refresh()


  createInviteButton: ->

    @addSubView @inviteButton = new KDButtonView
      title    : 'INVITE SOMEONE'
      cssClass : 'solid compact green invite'
      callback : =>
        @tabView.showPaneByName 'Invite'
        @inviteButton.hide()