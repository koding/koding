kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDHeaderView = kd.HeaderView
KDView = kd.View
AccountListViewController = require '../controllers/accountlistviewcontroller'
PaymentHistoryListItem = require './paymenthistorylistitem'
showError = require 'app/util/showError'
SubscriptionView = require 'app/payment/subscriptionview'
PaymentMethodView = require 'app/payment/paymentmethodview'
UpdateCreditCardWorkflow = require 'app/payment/updatecreditcardworkflow'


module.exports = class AccountBilling extends KDView

  initialState: {
    subscription: null
    paymentMethod: null
    paymentHistory: null
  }

  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @initialState, options.state


  viewAppended: ->

    @addSubView @subscriptionWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'subscription-wrapper clearfix'

    @addSubView @paymentMethodWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-method-wrapper clearfix'

    @addSubView @paymentHistoryWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'payment-history-wrapper clearfix'


    @initSubscription()
    @initPaymentHistory()


  initSubscription: ->

    { paymentController } = kd.singletons

    @subscriptionWrapper.addSubView new KDHeaderView
      title : 'Subscriptions'

    paymentController.subscriptions (err, subscription) =>
      return showError err  if err?

      @state.subscription = subscription

      @subscription = new SubscriptionView {}, subscription

      @subscription.on 'ChangeSubscriptionRequested', ->
        kd.singletons.router.handleRoute '/Pricing'

      @subscriptionWrapper.addSubView @subscription

      @initPaymentMethod subscription


  noItemView = (partial) ->
    return new KDCustomHTMLView
      cssClass : 'no-item'
      partial  : partial


  putPaymentMethodView: (paymentMethod) ->

    @paymentMethod?.destroy()

    @state.paymentMethod = paymentMethod

    @paymentMethod = new PaymentMethodView
      editLink    : yes
      removeLink  : no
    , paymentMethod

    @paymentMethod.on 'PaymentMethodEditRequested', @bound 'startWorkflow'

    @paymentMethodWrapper.addSubView @paymentMethod


  initPaymentMethod: (subscription) ->

    { paymentController } = kd.singletons

    @paymentMethodWrapper.addSubView new KDHeaderView
      title : 'Payment Method'

    paymentController.creditCard (err, cc) =>

      card = null  if err?

      if subscription.provider is 'stripe' and subscription.state isnt 'expired'
        card = cc

      @putPaymentMethodView card


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


