class AccountPaymentMethodsListController extends AccountListViewController


  constructor:(options,data)->

    options.noItemFoundText = "You have no payment method."

    super options, data

    data = @getData()

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    list = @getListView()

    list.on 'ItemWasAdded', (item) =>
      item.on 'PaymentMethodEditRequested', @bound 'editPaymentMethod'
      item.on 'PaymentMethodRemoveRequested', (data) =>
        modal = KDModalView.confirm
          title       : 'Are you sure?'
          description : 'Are you sure that you want to remove this payment method?'
          subView     : new PaymentMethodView {}, data
          ok          :
            title     : 'Remove'
            callback  : =>
              modal.destroy()
              @removePaymentMethod data, item

    list.on 'reload', (data) => @loadItems()

    list.addSubView new KDCustomHTMLView
      tagName : "script"
      attributes :
        src : "http://www.google.com/recaptcha/api/js/recaptcha_ajax.js"

    KD.getSingleton('paymentController').on 'PaymentDataChanged', => @loadItems()

  editPaymentMethod: (data) ->
    paymentController = KD.getSingleton 'paymentController'
    @showModal data

  removePaymentMethod: ({ paymentMethodId }, item) ->
    paymentController = KD.getSingleton 'paymentController'
    paymentController.removePaymentMethod paymentMethodId, =>
      @removeItem item

  loadItems: ->
    @removeAllItems()
    @showLazyLoader no

    KD.whoami().fetchPaymentMethods (err, paymentMethods) =>
      @instantiateListItems paymentMethods

      @addButton?.destroy()
      @getListView().addSubView @addButton = new KDCustomHTMLView
        cssClass  : 'kdlistitemview-cc plus'
        partial   : '<span><i></i><i></i></span>'
        click     : => @showModal()

      @hideLazyLoader()

  showModal: (initialPaymentInfo) ->
    paymentController = KD.getSingleton 'paymentController'

    modal = paymentController.createPaymentInfoModal()
    modal.on 'viewAppended', ->
      if initialPaymentInfo?
        modal.setState 'editExisting', initialPaymentInfo
      else
        modal.setState 'createNew'

    paymentController.observePaymentSave modal, (err, updatedPaymentInfo) =>
      return  if KD.showError err
      modal.destroy()


class AccountPaymentMethodsList extends KDListView

  constructor:(options = {},data)->

    options.tagName   = "ul"
    options.itemClass = AccountPaymentMethodsListItem

    super options,data


class AccountPaymentMethodsListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.tagName  = "li"
    options.type     = 'cc'

    super options,data

    data = @getData()

    @paymentMethod = new PaymentMethodView {}, @getData()

    @paymentMethod.on 'PaymentMethodEditRequested', =>
      @emit 'PaymentMethodEditRequested', data

    @editLink = new CustomLinkView
      title: 'edit'
      click: (e) =>
        e.preventDefault()
        @emit 'PaymentMethodEditRequested', data

    @removeLink = new CustomLinkView
      title: 'remove'
      click: (e) =>
        e.preventDefault()
        @emit 'PaymentMethodRemoveRequested', data

  pistachio:->
    """
    {{> @paymentMethod}}
    <div class="controls">{{> @editLink}} | {{> @removeLink }}</div>
    """