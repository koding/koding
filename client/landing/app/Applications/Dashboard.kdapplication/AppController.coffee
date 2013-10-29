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

      @paymentView.setPaymentInfo paymentMethod

  paymentViewAdded: (pane, view) ->

    paymentController = KD.getSingleton 'paymentController'

    group = @getData()

    @refreshPaymentView()

    paymentController.on 'PaymentDataChanged', => @refreshPaymentView()

    @paymentView = view

    view.on 'PaymentMethodEditRequested', => @showPaymentInfoModal()
    view.on 'PaymentMethodUnlinkRequested', (paymentMethod) =>
      modal = KDModalView.confirm
        title       : 'Are you sure?'
        description : 'Are you sure you want to unlink this payment method?'
        subView     : new PaymentMethodView {}, paymentMethod
        ok          :
          title     : 'Unlink'
          callback  : =>
            group.unlinkPaymentMethod paymentMethod.paymentMethodId, =>
              modal.destroy()
              @refreshPaymentView()

  productViewAdded: do ->

    confirmDelete = (callback) ->
      deleteModal = new KDModalView
        title        : "Warning"
        content      : "<div class='modalformline'>Are you sure you want to delete this item?</div>"
        height       : "auto"
        overlay      : yes
        buttons      :
          Remove     :
            loader   :
              color  : "#ffffff"
              diameter : 16
            style    : "modal-clean-red"
            callback : ->
              deleteModal.destroy()
              callback()
          cancel     :
            style    : "modal-cancel"
            callback : -> deleteModal.destroy()

    showCreateModal = (options, data, callback) ->
      productType = options.productType ? 'product'

      modal = new KDModalView
        overlay       : yes
        title         : "Create #{ productType }"

      createForm = new GroupProductEditForm options, data

      modal.addSubView createForm

      createForm.on 'CancelRequested', ->
        modal.destroy()

      createForm.on 'SaveRequested', (model, productData) ->
        modal.destroy()

        callback null, model, productData

    getProductFormOptions = (category) ->
      switch category

        when 'Product'
          productType     : 'product'
          isRecurOptional : yes
          showOverage     : yes
          showSoldAlone   : yes

        when 'Plan'
          productType     : 'plan'
          isRecurOptional : no
          showOverage     : no
          showSoldAlone   : no
          placeholders    :
            title         : 'e.g. "Gold Plan"'
            description   : 'e.g. "2 VMs, and a tee shirt"'

    getConstructor = (category) ->
      KD.remote.api["JPayment#{ category.capitalize() }"]

    prepareProductView = (view, category) ->
      group = KD.getGroup()
      konstructor = getConstructor category

      reload = ->
        group["fetch#{category}s"] (err, results) ->
          view["set#{category}s"] results

      handleResponse = (err) ->
        return if KD.showError err

        reload()

      # view.on "#{category}CreateRequested", (productData) ->

      view.on "#{category}DeleteRequested", (code) ->
        confirmDelete -> konstructor.removeByCode code, handleResponse

      view.on "#{category}EditRequested", (data) ->
        options = getProductFormOptions category

        showCreateModal options, data, (err, model, productData) ->
          return if KD.showError err

          if model
            model.modify productData, handleResponse
          else
            konstructor.create productData, handleResponse

      reload()

    productViewAdded = (pane, view) ->
      prepareProductView view, 'Product'
      prepareProductView view, 'Plan'

  showPaymentInfoModal: ->
    modal = @createPaymentInfoModal()

    paymentController = KD.getSingleton 'paymentController'

    paymentController.observePaymentSave modal, (err, { paymentMethodId }) =>
      if err
        new KDNotificationView title: err.message
      else
        modal.destroy()
        @getData().linkPaymentMethod paymentMethodId, (err) =>
          if err
            new KDNotificationView title: err.message
          @refreshPaymentView()

#    modal.on 'CountryDataPopulated', -> callback null, modal
    modal

  createPaymentInfoModal: ->

    paymentController = KD.getSingleton "paymentController"

    paymentMethodModal = paymentController.createPaymentInfoModal 'group'

    group = @getData()

    group.fetchPaymentMethod (err, groupPaymentMethod) =>

      if groupPaymentMethod

        paymentMethodModal.setState 'editExisting', groupPaymentMethod

      else

        KD.whoami().fetchPaymentMethods (err, personalPaymentMethods) =>

          if personalPaymentMethods.length

            paymentMethodModal.setState 'selectPersonal', personalPaymentMethods
            paymentMethodModal.on 'PaymentMethodSelected', (paymentMethodId) =>

              group.linkPaymentMethod paymentMethodId, (err) =>
                new KDNotificationView title: err.message  if err

                paymentMethodModal.destroy()
                @refreshPaymentView()

          else

            paymentMethodModal.setState 'createNew'


    return paymentMethodModal

  # vocabularyViewAdded:(pane, view)->
  #   group = view.getData()
  #   group.fetchVocabulary (err, vocab)-> view.setVocabulary vocab
  #   view.on 'VocabularyCreateRequested', ->
  #     {JVocabulary} = KD.remote.api
  #     JVocabulary.create {}, (err, vocab)-> view.setVocabulary vocab

  # bundleViewAdded:(pane, view)-> console.log 'bundle view', view
