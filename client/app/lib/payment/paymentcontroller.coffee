sinkrow = require 'sinkrow'
$ = require 'jquery'
getGroup = require '../util/getGroup'
remote = require('../remote').getInstance()
whoami = require '../util/whoami'
showError = require '../util/showError'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDController = kd.Controller
KDModalView = kd.ModalView
KDNotificationView = kd.NotificationView
JView = require '../jview'
PaymentWorkflow = require './paymentworkflow'
SubscriptionView = require './subscriptionview'
PaymentFormModal = require './paymentformmodal'
PlanUpgradeConfirmForm = require './planupgradeconfirmform'


module.exports = class PaymentController extends KDController

  DEFAULT_PROVIDER = 'stripe'

  api: -> remote.api.Payment


  subscribe: (token, planTitle, planInterval, options, callback) ->

    {planAmount, binNumber, lastFour, cardName} = options

    params = {
      token, planTitle, planInterval, planAmount
      binNumber, lastFour, cardName
    }

    params.email    = options.email    if options.email
    params.provider = options.provider or DEFAULT_PROVIDER

    @api().subscribe params, (err, result) =>
      @emit 'UserPlanUpdated'  unless err?
      callback err, result


  subscriptions : (callback) -> @api().subscriptions {}, callback
  invoices      : (callback) -> @api().invoices {}, callback


  creditCard: (callback) ->

    @api().creditCard {}, (err, card) ->

      card = null  if isNoCard card

      return callback err, card


  canUserPurchase: (callback) -> @api().canUserPurchase callback


  updateCreditCard: (token, callback) ->

    params          = {token}
    params.provider = DEFAULT_PROVIDER

    @api().updateCreditCard params, callback


  canChangePlan: (planTitle, callback) ->

    @api().canChangePlan {planTitle}, callback


  getPaypalToken: (planTitle, planInterval, callback) ->

    @api().getToken {planTitle, planInterval}, callback


  logOrder: (params, callback) ->

    @api().logOrder params, callback


  paypalReturn: (err) -> @emit 'PaypalRequestFinished', err
  paypalCancel: ->

  isNoCard = (data) ->

    return no  unless data

    noCard =
      data.last4 is '' and
      data.year  is 0 and
      data.month is 0

    return noCard

  ##########################################################

  fetchPaymentMethods: (callback) ->

    methods                = null
    preferredPaymentMethod = null
    {appStorageController} = kd.singletons
    appStorage             = appStorageController.storage 'Account', '1.0'

    queue      = [

      -> appStorage.fetchStorage ->
        preferredPaymentMethod = appStorage.getValue 'preferredPaymentMethod'
        queue.fin()

      => whoami().fetchPaymentMethods (err, paymentMethods) ->
        methods = paymentMethods
        queue.fin err
    ]

    sinkrow.dash queue, (err) -> callback err, {
      preferredPaymentMethod
      methods
      appStorage
    }

  observePaymentSave: (modal, callback) ->
    modal.on 'PaymentInfoSubmitted', (paymentMethodId, updatedPaymentInfo) =>
      # updatedPaymentInfo.challenge = Recaptcha.get_challenge()
      # updatedPaymentInfo.response  = Recaptcha.get_response()

      @updatePaymentInfo paymentMethodId, updatedPaymentInfo, (err, savedPaymentInfo) =>
        if err
          modal.paymentForm?.stopLoader()

          modal.emit 'FormValidationFailed', err
          return callback err

        callback null, savedPaymentInfo
        @emit 'PaymentDataChanged'

  removePaymentMethod: (paymentMethodId, callback) ->
    { JPayment } = remote.api
    JPayment.removePaymentMethod paymentMethodId, (err) =>
      return callback err  if err
      @emit 'PaymentDataChanged'

  fetchSubscription: do ->
    findActiveSubscription = (subscriptions, planCode, callback) ->
      for own paymentMethodId, subs of subscriptions
        for sub in subscriptions
          if sub.planCode is planCode and sub.status in ['canceled', 'active']
            return callback null, sub

      callback null

    fetchSubscription = (type, planCode, callback) ->
      { JPaymentSubscription } = remote.api

      if type is 'group'
        getGroup().checkPayment (err, subs) =>
          findActiveSubscription subs, planCode, callback
      else
        JPaymentSubscription.fetchUserSubscriptions (err, subs) ->
          findActiveSubscription subs, planCode, callback

  fetchPlanByCode: (planCode, callback) ->

    { JPaymentPlan } = remote.api

    JPaymentPlan.fetchPlanByCode planCode, callback

  fetchPaymentInfo: (type, callback) ->

    { JPaymentPlan } = remote.api

    switch type
      when 'group', 'expensed'
        getGroup().fetchPaymentInfo callback
      when 'user'
        JPaymentPlan.fetchAccountDetails callback

  isCaptchaValid: (challenge, response, callback)->
    $.ajax
      type    : "POST"
      url     : "/recaptcha"
      data    : {
        challenge : challenge,
        response  : response,
      }
      error   : -> callback "fail"
      success : (data)-> callback data
      timeout : 5000

  updatePaymentInfo: (paymentMethodId = null, paymentMethod, callback) ->
    {JPayment} = remote.api
    paymentMethod[key] = value.trim()  for own key, value of paymentMethod
    JPayment.setPaymentInfo paymentMethodId, paymentMethod, callback

  createPaymentInfoModal: -> new PaymentFormModal

  createUpgradeForm: (parent) ->
    buyPacksButton = new KDButtonView
      cssClass     : "buy-packs"
      style        : "solid green medium"
      title        : "Buy Resource Packs"
      callback     : ->
        parent   or= @parent
        parent.emit "Cancel"
        kd.singleton("router").handleRoute "/Pricing"

    return new JView
      pistachioParams:
        button  : buyPacksButton
      pistachio :
        """
        <h2>
          You do not have enough resources, you need to buy at least one "Resource Pack" to be able to create an extra VM.
        </h2>
        {{> button}}
        """

  createUpgradeWorkflow: (options = {}) ->
    {tag, productForm, confirmForm} = options

    productForm or= @createUpgradeForm()
    confirmForm or= new PlanUpgradeConfirmForm
      name : 'overview'
    workflow      = new PaymentWorkflow {productForm, confirmForm}

    productForm
      .on 'PlanSelected', (plan, planOptions) ->
        callback = ->
          workflow.collectData productData: { plan, planOptions }

        {oldSubscription} = workflow.collector.data
        unless oldSubscription
        then callback()
        else
          usage = oldSubscription?.usage ? {}
          plan.checkQuota {usage}, (err) ->
            return  if showError err
            callback()

      .on 'CurrentSubscriptionSet', (oldSubscription) ->
        workflow.collectData { oldSubscription }

    workflow
      .on 'DataCollected', (data) =>
        @transitionSubscription data, (err, subscription, rest...) ->
          return workflow.emit 'Failed', err  if err
          workflow.emit 'SubscriptionTransitionCompleted', subscription  unless err
          workflow.emit 'Finished', data, err, subscription, rest...

      .on 'Finished', (data, err, subscription, rest...) =>
        { plan, email, createAccount, paymentMethod: {billing} } = data
        if err?.short is 'existing_subscription'
          { existingSubscription } = err
          if existingSubscription.status is 'active'
            new KDNotificationView title: "You are already subscribed to this plan!"
            kd.getSingleton('router').handleRoute '/Account/Subscriptions'
          else
            existingSubscription.plan = plan
            @confirmReactivation existingSubscription, (err, subscription) =>
              return showError err  if err
              @emit "SubscriptionReactivated", subscription
        else if createAccount
          { cardFirstName: firstName, cardLastName: lastName } = billing
          { JUser } = remote.api
          JUser.convert { firstName, lastName, email }, (err) =>
            return showError err  if err
            JUser.logout ->
        else
          @emit "SubscriptionCompleted"

        kd.log 'kd.singletons.dock.getView().show()'

      .enter()

    workflow

  confirmReactivation: (subscription, callback) ->
    modal = KDModalView.confirm
      title       : 'Inactive subscription'
      description :
        """
        Your existing subscription for this plan has been canceled.  Would
        you like to reactivate it?
        """
      subView     : new SubscriptionView {}, subscription
      ok          :
        title     : 'Reactivate'
        callback  : -> subscription.resume (err) ->
          return callback err  if err

          modal.destroy()

          callback null, subscription

  createSubscription: (options, callback) ->
    { plan, planOptions, promotionType, paymentMethod } = options
    { paymentMethodId } = paymentMethod
    planOptions ?= {}
    { planApi } = planOptions

    options = {
      planOptions
      promotionType
      paymentMethodId
      planCode: plan.planCode
    }

    if planApi
      planApi.subscribe options, callback
    else
      plan.subscribe paymentMethodId, planOptions, callback

  transitionSubscription: (formData, callback) ->
    { productData, oldSubscription, promotionType, paymentMethod, createAccount, email } = formData
    { plan, planOptions } = productData
    { planCode } = plan
    { paymentMethodId } = paymentMethod
    if oldSubscription
      oldSubscription.transitionTo { planCode, paymentMethodId }, callback
    else
      @createSubscription {
        plan
        planOptions
        promotionType
        email
        paymentMethod
        createAccount
      }, callback

  debitSubscription: (subscription, pack, callback) ->
    subscription.debit { pack }, (err, nonce) =>
      return callback err  if err
      @emit 'SubscriptionDebited', subscription
      callback null, nonce

  creditSubscription: (subscription, pack, callback) ->
    subscription.credit { pack }, (err) =>
      return callback err  if err
      @emit 'SubscriptionCredited', subscription
      callback()

  fetchActiveSubscription: (tags, callback) ->
    if getGroup()?.slug is "koding"
      return callback()  if whoami().type isnt "registered"
      status = $in: ["active", "canceled"]
      @fetchSubscriptionsWithPlans {tags, status}, (err, subscriptions) ->
        return callback err  if err
        noSync = null
        active = null

        for subscription in subscriptions
          if "nosync" in subscription.tags
            noSync = subscription
          else
            active = subscription

        subscription = active or noSync

        if subscription
        then callback null, subscription
        else callback message: "Subscription not found", code: "no subscription"
    else
      @fetchGroupSubscription callback

  fetchGroupSubscription: (callback) ->
    getGroup().fetchSubscription callback

  fetchSubscriptionsWithPlans: (options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}

    whoami().fetchPlansAndSubscriptions options, (err, plansAndSubs) =>
      return callback err  if err

      { subscriptions } = @groupPlansBySubscription plansAndSubs

      callback null, subscriptions

  groupPlansBySubscription: (plansAndSubscriptions = {}) ->

    { plans, subscriptions } = plansAndSubscriptions

    plansByCode = plans.reduce( (memo, plan) ->
      memo[plan.planCode] = plan
      memo
    , {})

    for subscription in subscriptions
      subscription.plan = plansByCode[subscription.planCode]

    { plans, subscriptions }

  canDebitPack: (options = {}, callback = kd.noop) ->
    {subscriptionTag, packTag, multiplyFactor} = options
    multiplyFactor ?= 1

    return kd.warn "missing parameters"  unless subscriptionTag or packTag

    @fetchActiveSubscription tags: subscriptionTag, (err, subscription) ->
      remote.api.JPaymentPack.one tags: packTag, (err, pack) ->
        subscription.checkUsage pack, multiplyFactor, callback
