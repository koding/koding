kd                        = require 'kd'
showError                 = require 'app/util/showError'
trackEvent                = require 'app/util/trackEvent'
SubscriptionView          = require 'app/payment/subscriptionview'
PaymentMethodView         = require 'app/payment/paymentmethodview'
PaymentHistoryListItem    = require './paymenthistorylistitem'
UpdateCreditCardWorkflow  = require 'app/payment/updatecreditcardworkflow'
AccountListViewController = require '../controllers/accountlistviewcontroller'


module.exports = class AccountBilling extends kd.View

  initialState: {
    subscription: null
    paymentHistory: null
  }

  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @initialState, options.state


  viewAppended: ->

    @addSubView @subscriptionWrapper = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'subscription-wrapper clearfix'

    @addSubView @paymentHistoryWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-history-wrapper clearfix'


    @initSubscription()
    @initPaymentHistory()


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

      trackEvent 'Account Upgrade, click',
        path     : '/Account/Billing'
        category : 'userInteraction'
        action   : 'clicks'
        label    : 'billingUpgrade'

    paymentController.subscriptions (err, subscription) =>
      return showError err  if err?

      @state.subscription = subscription

      @subscription = new SubscriptionView {}, subscription

      @subscriptionWrapper.addSubView @subscription


  noItemView = (partial) ->
    return new kd.CustomHTMLView
      cssClass : 'no-item'
      partial  : partial


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


  startWorkflow: ->

    @workflow = new UpdateCreditCardWorkflow { delegate: this }

    @workflow.once 'UpdateCreditCardWorkflowFinishedSuccessfully', @bound 'handleFinishedWithSuccess'


  handleFinishedWithSuccess: ({ paymentMethod }) ->

    @putPaymentMethodView paymentMethod


