class AccountPaymentMethodsListController extends KDListViewController
  constructor:(options,data)->
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

    KD.remote.api.JRecurlyPlan.getUserAccount (err, res) =>
      accounts = []
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        if res.cardNumber
          accounts.push
            title        : "#{res.cardFirstName} #{res.cardLastName}"
            type         : res.cardType
            cardNumber   : res.cardNumber
            cardExpiry   : res.cardMonth + '/' + res.cardYear
            cardAddress  : res.address1 + ' ' + res.address2
            cardCity     : res.city
            cardState    : res.state
            cardZip      : res.zip
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
        @getListView().showModal @

class AccountPaymentMethodsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentMethodsListItem
    ,options
    super options,data

  showModal: (controller) ->
    KD.remote.api.JRecurlyPlan.getUserAccount (err, data)=>
      if err or not data
        data = {}

      paymentController = KD.getSingleton "paymentController"
      modal = paymentController.createPaymentMethodModal data, (newData, onError, onSuccess) ->
        KD.remote.api.JRecurlyPlan.setUserAccount newData, (err, result)->
          if err
            onError err
          else
            controller.emit 'reload'
            onSuccess result

      form = modal.modalTabs.forms["Billing Info"]

      # Credit card icon
      form.fields['cardNumber'].addSubView icon = new KDCustomHTMLView tagName : "span", cssClass : "icon"

      form.inputs['cardNumber'].on "CreditCardTypeIdentified", (type)=>
        cardType = type.toLowerCase()
        $icon = icon.$()
        unless $icon.hasClass cardType
          $icon.removeClass "visa mastercard discover amex"
          $icon.addClass cardType

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