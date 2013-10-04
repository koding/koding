class AccountPaymentMethodsListController extends AccountListViewController
  constructor:(options,data)->

    options.noItemFoundText = "You have no payment method."
    super options,data

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    list = @getListView()
    list.on 'reload', (data)=>
      @loadItems()

  loadItems: ->
    @removeAllItems()
    @showLazyLoader no
    KD.remote.api.JRecurlyPlan.getAccount (err, res) =>
      accounts = []
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        if res.billing
          { cardFirstName, cardLastName, cardNumber, cardType, cardMonth,
            cardYear, address1, address2, city, state, zip } = res.billing

          accounts.push
            title        : "#{cardFirstName} #{cardLastName}"
            type         : cardType
            cardNumber   : cardNumber
            cardExpiry   : [ cardMonth, cardYear ].join '/'
            cardAddress  : [ address1, address2 ].filter(Boolean).join ' '
            cardCity     : city
            cardState    : state
            cardZip      : zip
        @instantiateListItems accounts
        @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : =>
        @getListView().showModal this

class AccountPaymentMethodsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentMethodsListItem
    ,options
    super options,data

  showModal: (controller) ->
    paymentController = KD.getSingleton 'paymentController'
    modal = paymentController.createBillingInfoModal 'user', {}
    paymentController.fetchBillingInfo 'user', (err, initialBillingInfo) ->

      modal.setBillingInfo initialBillingInfo.billing

      modal.on 'PaymentInfoSubmitted', (updatedBillingInfo) ->
        paymentController.updateBillingInfo updatedBillingInfo


      form = modal.modalTabs.forms["Billing Info"]


class AccountPaymentMethodsListItem extends KDListItemView
  constructor:(options,data)->
    options.tagName = "li"
    super options,data

  viewAppended:->
    @setPartial @partial @data

  partial:(data)->
    """
      <div class="credit-card-info">
        <p class="lightText"><strong>#{data.title} - #{data.type}</strong></p>
        <p class="lightText"><strong>#{data.cardNumber}</strong> - <strong>#{data.cardExpiry}</strong></p>
        <p class="darkText">
          #{data.cardAddress}<br>
          #{data.cardCity}, #{data.cardState} #{data.cardZip}
        </p>
      </div>
    """