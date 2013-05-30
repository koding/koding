class DashboardAppController extends AppController

  KD.registerAppClass this,
    name         : "Dashboard"
    route        : "/Dashboard"
    behavior     : "hideTabs"
    hiddenHandle : yes

  constructor:(options={},data)->

    options.view = new DashboardAppView
    data or= @getSingleton("groupsController").getCurrentGroup()

    super options, data

    @tabData = [
      #   name        : 'Readme'
      #   viewOptions :
      #     viewClass : GroupReadmeView
      #     lazy      : no
      # ,
        name        : 'Settings'
        viewOptions :
          viewClass : GroupGeneralSettingsView
          lazy      : yes
      ,
        name        : 'Permissions'
        viewOptions :
          viewClass : GroupPermissionsView
          lazy      : yes
      ,
        name        : 'Members'
        viewOptions :
          viewClass : GroupsMemberPermissionsView
          lazy      : yes
          callback  : @membersViewAdded
      ,
        name        : 'Membership policy'
        viewOptions :
          viewClass : GroupsMembershipPolicyDetailView
          lazy      : yes
          callback  : @policyViewAdded
      ,
        name        : 'Invitations'
        viewOptions :
          viewClass : GroupsInvitationRequestsView
          lazy      : yes
          callback  : @invitationsViewAdded

      # CURRENTLY DISABLED

      # ,
      #   name        : 'Vocabulary'
      #   viewOptions :
      #     viewClass : GroupsVocabulariesView
      #     lazy      : yes
      #     callback  : @vocabularyViewAdded
      # ,
      #   name        : 'Bundle'
      #   viewOptions :
      #     viewClass : GroupsBundleView
      #     lazy      : yes
      #     callback  : @bundleViewAdded
    ]

  fetchTabData:(callback)-> callback @tabData

  membersViewAdded:(pane, view)->
    group = view.getData()
    # pane.on 'PaneDidShow', ->
    #   view.refresh()  if pane.tabHandle.isDirty
    #   pane.tabHandle.markDirty no
    group.on 'MemberAdded', ->
      log 'MemberAdded'
      # {tabHandle} = pane
      # tabHandle.markDirty()

  policyViewAdded:(pane, view)->

  invitationsViewAdded:(pane, view)->
    group = view.getData()
    kallback = (modal, err)=>
      form = modal.modalTabs.forms.invite
      form.buttons.Send.hideLoader()
      view.refresh()
      if err
        unless Array.isArray err or form.fields.report
          return view.showErrorMessage err
        else
          form.fields.report.show()
          scrollView = form.fields.report.subViews.first.subViews.first
          err.forEach (errLine)->
            errLine = if errLine?.message then errLine.message else errLine
            scrollView.setPartial "#{errLine}<br/>"
          return scrollView.scrollTo top:scrollView.getScrollHeight()

      new KDNotificationView title:'Invitation sent!'
      modal.destroy()

    view.on 'BatchApproveRequests', (formData)->
      group.sendSomeInvitations formData.count, (err)=>
        return view.showErrorMessage err if err
        view.updateCurrentState()
        kallback @batchApprove, err

    view.on 'InviteByEmail', (formData)->
      group.inviteByEmails formData.emails, (err)=>
        kallback @inviteByEmail, err

    view.on 'InviteByUsername', (formData)->
      group.inviteByUsername formData.recipients, (err)=>
        kallback @inviteByUsername, err

    view.on 'RequestIsApproved', (request, callback)->
      request.approve callback

    view.on 'RequestIsDeclined', (request, callback)->
      request.declineInvitation callback

    pane.on 'PaneDidShow', ->
      view.refresh()  if pane.tabHandle.isDirty
      # pane.tabHandle.markDirty no

    group.on 'NewInvitationRequest', ->
      pane.emit 'NewInvitationActionArrived'
      # pane.tabHandle.markDirty()

  vocabularyViewAdded:(pane, view)->
    group = view.getData()
    group.fetchVocabulary (err, vocab)-> view.setVocabulary vocab
    view.on 'VocabularyCreateRequested', ->
      {JVocabulary} = KD.remote.api
      JVocabulary.create {}, (err, vocab)-> view.setVocabulary vocab

  bundleViewAdded:(pane, view)-> console.log 'bundle view', view