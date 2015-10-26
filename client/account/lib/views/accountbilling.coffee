kd                        = require 'kd'
showError                 = require 'app/util/showError'
SubscriptionView          = require 'app/payment/subscriptionview'
PaymentMethodView         = require 'app/payment/paymentmethodview'
PaymentHistoryListItem    = require './paymenthistorylistitem'
UpdateCreditCardWorkflow  = require 'app/payment/updatecreditcardworkflow'
AccountListViewController = require '../controllers/accountlistviewcontroller'
PaymentConstants          = require 'app/payment/paymentconstants'


module.exports = class AccountBilling extends kd.View


  { KEY, DURATION } = PaymentConstants.FAILED_ATTEMPTS.UPDATE_CREDIT_CARD


  initialState: {
    subscription: null
    paymentMethod: null
    paymentHistory: null
  }

  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @initialState, options.state

    { appStorageController } = kd.singletons
    @accountStorage          = appStorageController.storage 'Account', '1.0'


  viewAppended: ->

    @addSubView @subscriptionWrapper = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'subscription-wrapper clearfix'

    @addSubView @paymentMethodWrapper = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-method-wrapper clearfix'

    @addSubView @paymentHistoryWrapper = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-history-wrapper clearfix'

    @initSubscription()
    @initPaymentHistory()

    # put payment method view with empty data first,
    # fetch and populate later.
    @putPaymentMethodView null


  initSubscription: ->

    { paymentController } = kd.singletons

    @subscriptionWrapper.addSubView header = new kd.HeaderView
      title : 'Subscriptions'

    header.addSubView new kd.ButtonView
      style    : 'solid small green'
      title    : 'Upgrade'
      callback : @lazyBound 'emit', 'ChangeSubscriptionRequested'

    @on 'ChangeSubscriptionRequested', ->
      kd.singletons.router.handleRoute '/Pricing'
      @parent.emit 'ModalCloseRequested'

    paymentController.subscriptions (err, subscription) =>
      return showError err  if err?

      @state.subscription = subscription

      @subscription = new SubscriptionView {}, subscription

      @subscriptionWrapper.addSubView @subscription

      @initPaymentMethod subscription


  noItemView = (partial) ->
    return new kd.CustomHTMLView
      cssClass : 'no-item'
      partial  : partial


  putPaymentMethodView: (method) ->

    @paymentMethod?.destroy()

    @paymentMethod = new PaymentMethodView {}, method

    @paymentMethodWrapper.addSubView header = new kd.HeaderView
      title : 'Payment Method'

    header.addSubView button = new kd.ButtonView
      style    : 'solid small green'
      cssClass : 'hidden'
      title    : 'Update'
      callback : @bound 'preventBlockedUser'

    @paymentMethodHeader = header
    @paymentMethodButton = button

    @paymentMethodWrapper.addSubView @paymentMethod


  initPaymentMethod: (subscription) ->

    { paymentController } = kd.singletons

    card = null
    paymentController.creditCard (err, result) =>

      if err
        card = null
      else
        { provider, state } = subscription
        creditCardExists = provider is 'stripe' and state isnt 'expired'

        # only show the button if card exists.
        card = result  if creditCardExists

      @setPaymentMethod card


  initPaymentHistory: ->

    { paymentController } = kd.singletons

    @paymentHistoryWrapper.addSubView new kd.HeaderView
      title : 'Payment History'

    paymentController.invoices (err, invoices) =>

      invoices = []  if err?

      @state.paymentHistory = invoices

      invoices = invoices.map (invoice) =>
        invoice.paymentMethod = { last4: '1234' }
        return invoice

      @listController = new AccountListViewController
        itemClass: PaymentHistoryListItem
        noItemFoundText: 'You have no payment history'
      , { items: invoices }

      @paymentHistoryWrapper.addSubView @listController.getView()


  preventBlockedUser: ->

    now = Date.now()

    @accountStorage.fetchValue KEY, (result) =>

      return @startWorkflow()  unless result

      difference = now - result.timestamp

      if difference < DURATION
        return @startWorkflow yes
      else
        @startWorkflow()
        @removeBlockFromUser()


  startWorkflow: (isFailedLimitReached) ->

    @workflow = new UpdateCreditCardWorkflow { delegate: this }
    @workflow.once 'UpdateCreditCardWorkflowFinishedSuccessfully', @bound 'handleFinishedWithSuccess'

    if isFailedLimitReached
      @workflow.once 'ModalIsReady', => @workflow.failedAttemptLimitReached no


  removeBlockFromUser: ->

    kd.utils.defer => @accountStorage.unsetKey KEY


  handleFinishedWithSuccess: ({ paymentMethod }) ->

    @setPaymentMethod paymentMethod


  setPaymentMethod: (method) ->

    @state.paymentMethod = method

    if method
    then @paymentMethodButton.show()
    else @paymentMethodButton.hide()

    @paymentMethod.setPaymentInfo method
