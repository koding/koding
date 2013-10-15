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

  constructor: (options = {}, data) ->

    options.view = new DashboardAppView
      testPath   : "groups-dashboard"

    data or= (KD.getSingleton "groupsController").getCurrentGroup()

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
          callback   : @bound 'membersViewAdded'
      ,
        name         : 'Invitations'
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
        hiddenHandle : @getData().privacy is 'public'
        viewOptions  :
          viewClass  : GroupsMembershipPolicyDetailView
          lazy       : yes
          callback   : @bound 'policyViewAdded'
      ,
        name         : 'Payment'
        viewOptions  :
          viewClass  : GroupPaymentSettingsView
          lazy       : yes
          callback   : @bound 'paymentViewAdded'
      ,
        name         : 'Products'
        viewOptions  :
          viewClass  : GroupProductSettingsView
          lazy       : yes
          callback   : @bound 'productViewAdded'
      ,
        name         : 'Blocked Users'
        hiddenHandle : @getData().privacy is 'public'
        kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
        viewOptions  :
          viewClass  : GroupsBlockedUserView
          lazy       : yes
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

  fetchTabData: (callback) -> @utils.defer => callback @tabData

  membersViewAdded: (pane, view) ->
    group = view.getData()
    # pane.on 'PaneDidShow', ->
    #   view.refresh()  if pane.tabHandle.isDirty
    #   pane.tabHandle.markDirty no
    group.on 'MemberAdded', ->
      log 'MemberAdded'
      # {tabHandle} = pane
      # tabHandle.markDirty()

  policyViewAdded: (pane, view) ->

  refreshPaymentView: ->
    group = @getData()
    group.fetchPaymentMethod (err, paymentMethod) =>
      return new KDNotificationView title: err.message  if err

      @paymentView.setBillingInfo paymentMethod

  paymentViewAdded: (pane, view) ->

    paymentController = KD.getSingleton 'paymentController'

    group = @getData()

    @refreshPaymentView()

    @paymentView = view

    view.on 'BillingEditRequested', => @showBillingInfoModal()
    view.on 'PaymentMethodUnlinkRequested', (billingInfo) =>
      modal = KDModalView.confirm
        title       : 'Are you sure?'
        description : 'Are you sure you want to unlink this payment method?'
        subView     : new BillingMethodView {}, billingInfo
        ok          :
          title     : 'Remove'
          callback  : =>
            group.unlinkPaymentMethod billingInfo.accountCode, =>
              modal.destroy()
              @refreshPaymentView()

  productViewAdded: (pane, view) ->


  showBillingInfoModal: ->
    modal = @createBillingInfoModal()

    modal.on 'PaymentInfoSubmitted', (formData) =>
      @getData().setBillingInfo formData, (err) =>
        console.error err  if err

        @paymentView?.setBillingInfo formData

        modal.destroy()

#    modal.on 'CountryDataPopulated', -> callback null, modal

  createBillingInfoModal: ->

    paymentController = KD.getSingleton "paymentController"

    billingInfoModal = paymentController.createBillingInfoModal 'group'

    group = @getData()

    group.fetchPaymentMethod (err, groupBillingMethod) =>

      if groupBillingMethod

        billingInfoModal.setState 'editExisting', groupBillingMethod

      else

        KD.whoami().fetchPaymentMethods (err, personalBillingMethods) =>

          if personalBillingMethods.length

            billingInfoModal.setState 'selectPersonal', personalBillingMethods
            billingInfoModal.on 'BillingMethodSelected', (accountCode) =>

              group.linkPaymentMethod accountCode, (err) =>
                new KDNotificationView title: err.message  if err

                billingInfoModal.destroy()
                @refreshPaymentView()

          else

            billingInfoModal.setState 'createNew'


    return billingInfoModal

  # vocabularyViewAdded:(pane, view)->
  #   group = view.getData()
  #   group.fetchVocabulary (err, vocab)-> view.setVocabulary vocab
  #   view.on 'VocabularyCreateRequested', ->
  #     {JVocabulary} = KD.remote.api
  #     JVocabulary.create {}, (err, vocab)-> view.setVocabulary vocab

  # bundleViewAdded:(pane, view)-> console.log 'bundle view', view
