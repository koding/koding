class GroupsInvitationRequestsTabView extends KDTabView

  constructor:(options={}, data)->
    options.cssClass             or= 'invitations-tabs'
    options.maxHandleWidth       or= 170
    options.hideHandleCloseIcons  ?= yes

    super options, data

    @buttonContainer = new KDView cssClass: 'button-bar'
    @getTabHandleContainer().addSubView @buttonContainer

    @showResolvedView = new KDView cssClass : 'show-resolved'
    @showResolvedView.addSubView showResolvedLabelView = new KDLabelView
      title    : 'Show Resolved: '
    @showResolvedView.addSubView new KDOnOffSwitch
      label    : showResolvedLabelView
      callback : (@resolvedState)=> @setResolvedStateInView()

    @approvalEnabled = @getDelegate().policy.approvalEnabled
    @resolvedState = no

    @createTabs()
    @addHeaderButtons()

    @listenWindowResize()
    @on 'viewAppended', @bound '_windowDidResize'
    @on 'PaneDidShow',  @bound 'paneDidShow'

  paneDidShow:->
    @decorateHeaderButtons()
    view = @getActivePane().subViews.first
    @setResolvedStateInView()  if view.resolvedState isnt @resolvedState

  setResolvedStateInView:->
    view = @getActivePane().subViews.first
    view.setStatusesByResolvedSwitch @resolvedState
    view.refresh()

  createTabs:->
    for tab, i in @getTabs()
      tab.viewOptions.data    = @getData()
      tab.viewOptions.options = delegate: this
      @addPane new KDTabPaneView(tab), i is 0

  addHeaderButtons:->
    bulkSubject = if @approvalEnabled then 'Approve' else 'Invite'

    @buttonContainer.addSubView @showResolvedView
    @buttonContainer.addSubView @bulkApproveButton = new KDButtonView
      title    : "Bulk #{bulkSubject}"
      cssClass : 'clean-gray'
      callback : @getDelegate().showBulkApproveModal.bind @getDelegate()
    @buttonContainer.addSubView @inviteByEmailButton = new KDButtonView
      title    : 'Invite by Email'
      cssClass : 'clean-gray'
      callback : @getDelegate().showInviteByEmailModal.bind @getDelegate()
    @buttonContainer.addSubView @createInvitationCodeButton = new KDButtonView
      title    : 'Create Invitation Code'
      cssClass : 'clean-gray'
      callback : @getDelegate().showCreateInvitationCodeModal.bind @getDelegate()

    @decorateHeaderButtons()

  decorateHeaderButtons:->
    button.hide()  for button in @buttonContainer.subViews.slice 1

    switch @getActivePane().name
      when 'Membership Requests'
        @bulkApproveButton.show()
      when 'Invitation Requests'
        @bulkApproveButton.show()
      when 'Invitations'
        @inviteByEmailButton.show()
      when 'Invitation Codes'
        @createInvitationCodeButton.show()

  getTabs:-> [
    name        : "#{if @approvalEnabled then 'Membership' else 'Invitation'} Requests"
    viewOptions :
      viewClass : GroupsMembershipRequestsTabPaneView
  ,
    name        : 'Invitations'
    viewOptions :
      viewClass : GroupsSentInvitationsTabPaneView
  ,
    name        : 'Invitation Codes'
    viewOptions :
      viewClass : GroupsInvitationCodesTabPaneView
  ]

  _windowDidResize:->
    @setHeight @parent.getHeight() - @getTabHandleContainer().getHeight()
