class AccountPaymentMethodsListController extends AccountListViewController
  constructor:(options,data)->

    options.noItemFoundText = "You have no payment method."
    super options, data

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    list = @getListView()

    list.on 'ItemWasAdded', (item) =>
      item.on 'PaymentMethodEditRequested', @bound 'editPaymentMethod'
      item.on 'PaymentMethodRemoveRequested', (data) =>
        modal = new KDModalView
          title: 'Are you sure?'
          content:
            """
            <div class='modalformline'>
              <p>
                Are you sure that you want to remove this payment method?
              </p>
            </div>
            """
          buttons:
            Remove:
              style: "modal-clean-red"
              callback: =>
                modal.destroy()
                @removePaymentMethod data, item
            cancel:
              style: "modal-cancel"
              callback: ->
                modal.destroy()
        modal.addSubView new BillingMethodView {}, data.billing

    list.on 'reload', (data) => @loadItems()

  editPaymentMethod: (data) ->
    paymentController = KD.getSingleton 'paymentController'
    @showModal data

  removePaymentMethod: ({ accountCode }, item) ->
    paymentController = KD.getSingleton 'paymentController'
    paymentController.removePaymentMethod accountCode, =>
      @removeItem item

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

  showModal: (initialBillingInfo) ->
    paymentController = KD.getSingleton 'paymentController'

    modal = paymentController.createBillingInfoModal()

    modal.setBillingInfo initialBillingInfo.billing  if initialBillingInfo?

    modal.on 'PaymentInfoSubmitted', (updatedBillingInfo) =>
      paymentController.updateBillingInfo initialBillingInfo?.accountCode, updatedBillingInfo, (err, res) =>
        if err
          new KDNotificationView title: err.message
        else
          modal.destroy()
          @loadItems()



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

    @billingMethod.on 'BillingEditRequested', =>
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

  viewAppended: JView::viewAppended

  pistachio:->
    """
    {{> @billingMethod}}
    <div class="controls">{{> @editLink}} | {{> @removeLink }}</div>
    """