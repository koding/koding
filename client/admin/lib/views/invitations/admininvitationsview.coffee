kd                      = require 'kd'
KDView                  = kd.View
KDTabView               = kd.TabView
KDButtonView            = kd.ButtonView
KDTabPaneView           = kd.TabPaneView
InviteSomeoneView       = require './invitesomeoneview'
SlackInviteView         = require './slackinviteview'
AdminSubTabHandleView   = require './../customviews/adminsubtabhandleview'
PendingInvitationsView  = require './pendinginvitationsview'
AcceptedInvitationsView = require './acceptedinvitationsview'

module.exports = class AdminInvitationsView extends KDView

  PANE_NAMES_BY_ROUTE =
    'Invite'   : 'Invite Teammates'
    'Slack'    : 'Invite with <cite class="slack"></cite>'
    'Pending'  : 'Pending Invitations'
    'Accepted' : 'Accepted Invitations'

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()

    kd.singletons.notificationController.on 'NewMemberJoinedToGroup', @bound 'refreshAllTabs'


  createTabView: ->

    data = @getData()

    @addSubView tabView = @tabView = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 210
      tabHandleClass       : AdminSubTabHandleView

    tabView.addPane invite   = new KDTabPaneView
      name         : PANE_NAMES_BY_ROUTE.Invite
      route        : '/Admin/Invitations/Invite'
    tabView.addPane slack   = new KDTabPaneView
      name         : PANE_NAMES_BY_ROUTE.Slack
      route        : '/Admin/Invitations/Slack'
    tabView.addPane pending  = new KDTabPaneView
      name         : PANE_NAMES_BY_ROUTE.Pending
      route        : '/Admin/Invitations/Pending'
    tabView.addPane accepted = new KDTabPaneView
      name         : PANE_NAMES_BY_ROUTE.Accepted
      route        : '/Admin/Invitations/Accepted'

    pending.addSubView  @pendingView  = new PendingInvitationsView  {}, data
    accepted.addSubView @acceptedView = new AcceptedInvitationsView {}, data
    invite.addSubView   inviteView    = new InviteSomeoneView       {}, data
    slack.addSubView    slackView     = new SlackInviteView         {}, data

    tabView.showPaneByIndex 0

    invite.on 'KDTabPaneActive', -> inviteView.inputViews.first?.email.setFocus()
    inviteView.on 'NewInvitationsAdded', => @pendingView.refresh()

    @on 'SubTabRequested', (action, identifier) -> tabView.showPaneByName PANE_NAMES_BY_ROUTE[action]


  refreshAllTabs: ->

    for view in [ @pendingView, @acceptedView ]
      view.refresh()
