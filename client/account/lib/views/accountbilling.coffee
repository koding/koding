kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDHeaderView = kd.HeaderView
KDView = kd.View
AccountListViewController = require '../controllers/accountlistviewcontroller'
PaymentHistoryListItem = require './paymenthistorylistitem'
showError = require 'app/util/showError'
SubscriptionView = require 'app/payment/subscriptionview'
UpdateCreditCardWorkflow = require 'app/payment/updatecreditcardworkflow'
trackEvent = require 'app/util/trackEvent'
KDButtonView = kd.ButtonView


module.exports = class AccountBilling extends KDView

  initialState: {
    subscription: null
    paymentHistory: null
  }

  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @initialState, options.state


  viewAppended: ->

    @addSubView @subscriptionWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'subscription-wrapper clearfix'

    @addSubView @paymentHistoryWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-history-wrapper clearfix'


    @initSubscription()
    @initPaymentHistory()


  initSubscription: ->

    { paymentController } = kd.singletons

    @subscriptionWrapper.addSubView header = new KDHeaderView
      title : 'Subscriptions'

    header.addSubView new KDButtonView
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
    return new KDCustomHTMLView
      cssClass : 'no-item'
      partial  : partial


  initPaymentHistory: ->

    { paymentController } = kd.singletons

    @paymentHistoryWrapper.addSubView new KDHeaderView
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


