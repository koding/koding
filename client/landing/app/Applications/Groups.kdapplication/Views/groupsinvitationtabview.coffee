class GroupsInvitationTabView extends KDTabView

  constructor:(options={}, data)->
    options.cssClass             or= 'invitations-tabs'
    options.maxHandleWidth       or= 300
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

    @on 'PaneAdded', (pane)=> pane.options.view.updatePendingCount pane

    @createTabs()
    @addHeaderButtons()

    @listenWindowResize()
    @on 'viewAppended', @bound '_windowDidResize'
    @on 'PaneDidShow',  @bound 'paneDidShow'

  paneDidShow:->
    @decorateHeaderButtons()
    {tabHandle, mainView} = @getActivePane()
    @setResolvedStateInView()  if mainView.resolvedState isnt @resolvedState
    mainView.refresh()  if tabHandle.isDirty
    tabHandle.markDirty no

  setResolvedStateInView:->
    view = @getActivePane().subViews.first
    view.setStatusesByResolvedSwitch @resolvedState
    view.refresh()

  createTabs:->
    for tab, i in @getTabs()
      tab.view = new tab.viewOptions.viewClass {delegate: this}, @getData()
      @addPane new KDTabPaneView(tab), i is 0

  addHeaderButtons:->
    bulkSubject = if @approvalEnabled then 'Approve' else 'Invite'

    @buttonContainer.addSubView @showResolvedView
    @buttonContainer.addSubView @editInvitationMessageButtion = new KDButtonView
      title    : "Edit Invitation Message"
      cssClass : 'clean-gray'
      callback : @getDelegate().showEditInviteMessageModal.bind @getDelegate()
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
        @editInvitationMessageButtion.show()
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
