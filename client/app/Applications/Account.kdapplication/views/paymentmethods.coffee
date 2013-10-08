class AccountPaymentMethodsListController extends AccountListViewController
  constructor:(options,data)->

    options.noItemFoundText = "You have no payment method."
    super options,data

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    list = @getListView()

    list.on 'ItemWasAdded', (item) =>
      item.on 'PaymentMethodEditRequested', @bound 'editPaymentMethod'
      item.on 'PaymentMethodRemoveRequested', (data) =>
        @removePaymentMethod data, item

    list.on 'reload', (data) => @loadItems()

  editPaymentMethod: ({ accountCode }) ->
    @showModal()

  removePaymentMethod: ({ accountCode }, item) ->
    paymentController = KD.getSingleton 'paymentController'
    paymentController.removePaymentMethod accountCode, =>
      debugger

  loadItems: ->
    @removeAllItems()
    @showLazyLoader no

    KD.whoami().fetchPaymentMethods (err, paymentMethods) =>
      @instantiateListItems paymentMethods
      @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : => @showModal()

  showModal: ->
    paymentController = KD.getSingleton 'paymentController'
    modal = paymentController.createBillingInfoModal 'user', {}
    paymentController.fetchBillingInfo 'user', (err, initialBillingInfo) ->

      modal.setBillingInfo initialBillingInfo.billing  if initialBillingInfo?

      modal.on 'PaymentInfoSubmitted', (updatedBillingInfo) ->
        paymentController.updateBillingInfo updatedBillingInfo


class AccountPaymentMethodsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentMethodsListItem
    ,options
    super options,data

class AccountPaymentMethodsListItem extends KDListItemView
  constructor:(options, data)->
    options.tagName = "li"
    options.cssClass = 'credit-card-list-item'
    super options,data

    data = @getData()

    @billingMethod = new BillingMethodView {}, @getData().billing

    @editLink = new CustomLinkView
      title: 'edit'
      click: => @emit 'PaymentMethodEditRequested', data

    @removeLink = new CustomLinkView
      title: 'remove'
      click: => @emit 'PaymentMethodRemoveRequested', data

  viewAppended: JView::viewAppended

  pistachio:->
    """
    {{> @billingMethod}}
    <div class="controls">{{> @editLink}} | {{> @removeLink }}</div>
    """