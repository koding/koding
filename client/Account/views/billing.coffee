class AccountBilling extends JView

  initialState: {
    subscription: {}
    paymentMethod: {}
    paymentHistory: {}
  }

  constructor: (options = {}, data) ->

    super options, data

    @state = @utils.extend @initialState, options.state

    @initViews()


  initViews: ->

    @subscriptionWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'subscription-wrapper clearfix'

    @paymentMethodWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-method-wrapper clearfix'

    @paymentHistoryWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-history-wrapper clearfix'


    @initSubscription()
    @initPaymentMethod()
    @initPaymentHistory()


  initSubscription: ->

    { paymentController } = KD.singletons

    @subscriptionWrapper.addSubView new KDHeaderView
      title : 'Subscriptions'

    paymentController.subscriptions (err, subscription) =>
      return KD.showError err  if err

      @state.subscription = subscription
      @subscriptionWrapper.addSubView new SubscriptionView {}, subscription


  noItemView = (partial) ->
    return new KDCustomHTMLView
      cssClass : 'no-item'
      partial  : partial


  initPaymentMethod: ->

    { paymentController } = KD.singletons

    @paymentMethodWrapper.addSubView new KDHeaderView
      title : 'Payment Method'

    paymentController.creditCard (err, card) =>

      card = null  if err

      @state.paymentMethod = card

      methodView = new PaymentMethodView
        editLink    : yes
        removeLink  : no
      , card

      @paymentMethodWrapper.addSubView methodView


  initPaymentHistory: ->

    { paymentController } = KD.singletons

    @paymentHistoryWrapper.addSubView new KDHeaderView
      title : 'Payment History'

    paymentController.invoices (err, invoices) =>

      invoices = []  if err

      @state.paymentHistory = invoices

      invoices = invoices.map (invoice) =>
        invoice.paymentMethod = { last4: '1234' }
        return invoice

      @listController = new AccountListViewController
        itemClass: PaymentHistoryListItem
        noItemFoundText: 'You have no payment history'
      , { items: invoices }

      @paymentHistoryWrapper.addSubView @listController.getView()


  pistachio: ->
    """
    {{> @subscriptionWrapper}}
    {{> @paymentMethodWrapper}}
    {{> @paymentHistoryWrapper}}
    """

