class DashboardAppController extends AppController

  KD.registerAppClass this,
    name         : "Dashboard"
    route        : "/:name?/Dashboard"
    hiddenHandle : yes
    navItem      :
      title      : "Group"
      path       : "/Dashboard"
      order      : 75
      role       : "admin"
      type       : "account"

  constructor:(options={},data)->

    options.view = new DashboardAppView
    data or= KD.getSingleton("groupsController").getCurrentGroup()

    super options, data

    @tabData = [
      #   name        : 'Readme'
      #   viewOptions :
      #     viewClass : GroupReadmeView
      #     lazy      : no
      # ,
        name         : 'Settings'
        viewOptions  :
          viewClass  : GroupGeneralSettingsView
          lazy       : yes
      ,
        name         : 'Members'
        viewOptions  :
          viewClass  : GroupsMemberPermissionsView
          lazy       : yes
          callback   : @membersViewAdded
      ,
        name         : 'Invitations'
        hiddenHandle : data.privacy is 'public'
        viewOptions  :
          viewClass  : GroupsInvitationView
          lazy       : yes
      ,
        name         : 'Permissions'
        viewOptions  :
          viewClass  : GroupPermissionsView
          lazy       : yes
      ,
        name         : 'Membership policy'
        hiddenHandle : data.privacy is 'public'
        viewOptions  :
          viewClass  : GroupsMembershipPolicyDetailView
          lazy       : yes
          callback   : @policyViewAdded
      ,
        name         : 'Payment'
        viewOptions  :
          viewClass  : GroupPaymentSettingsView
          lazy       : yes
          callback   : @paymentViewAdded
      ,
        name         : 'Products'
        viewOptions  :
          viewClass  : GroupProductSettingsView
          lazy       : yes
          callback   : @productViewAdded

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

  paymentViewAdded:(pane, view)->

  productViewAdded:(pane, view)->

  vocabularyViewAdded:(pane, view)->
    group = view.getData()
    group.fetchVocabulary (err, vocab)-> view.setVocabulary vocab
    view.on 'VocabularyCreateRequested', ->
      {JVocabulary} = KD.remote.api
      JVocabulary.create {}, (err, vocab)-> view.setVocabulary vocab

  bundleViewAdded:(pane, view)-> console.log 'bundle view', view
