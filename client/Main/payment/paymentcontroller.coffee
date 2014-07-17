class PaymentController extends KDController

  fetchPaymentMethods: (callback) ->

    {dash}                 = Bongo
    methods                = null
    preferredPaymentMethod = null
    {appStorageController} = KD.singletons
    appStorage             = appStorageController.storage 'Account', '1.0'

    queue      = [

      -> appStorage.fetchStorage ->
        preferredPaymentMethod = appStorage.getValue 'preferredPaymentMethod'
        queue.fin()

      => KD.whoami().fetchPaymentMethods (err, paymentMethods) ->
        methods = paymentMethods
        queue.fin err
    ]

    dash queue, (err) -> callback err, {
      preferredPaymentMethod
      methods
      appStorage
    }

  observePaymentSave: (modal, callback) ->
    modal.on 'PaymentInfoSubmitted', (paymentMethodId, updatedPaymentInfo) =>
      challenge = Recaptcha.get_challenge()
      response = Recaptcha.get_response()

      @isCaptchaValid challenge, response, (result)=>
        modal.paymentForm.stopLoader()

        if result isnt "verified"
          callback "Captcha failed, please try again."
          return

        @updatePaymentInfo paymentMethodId, updatedPaymentInfo, (err, savedPaymentInfo) =>
          if err
            modal.emit 'FormValidationFailed', err
            return callback err
          callback null, savedPaymentInfo
          @emit 'PaymentDataChanged'

  removePaymentMethod: (paymentMethodId, callback) ->
    { JPayment } = KD.remote.api
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
      { JPaymentSubscription } = KD.remote.api

      if type is 'group'
        KD.getGroup().checkPayment (err, subs) =>
          findActiveSubscription subs, planCode, callback
      else
        JPaymentSubscription.fetchUserSubscriptions (err, subs) ->
          findActiveSubscription subs, planCode, callback

  fetchPlanByCode: (planCode, callback) ->

    { JPaymentPlan } = KD.remote.api

    JPaymentPlan.fetchPlanByCode planCode, callback

  fetchPaymentInfo: (type, callback) ->

    { JPaymentPlan } = KD.remote.api

    switch type
      when 'group', 'expensed'
        KD.getGroup().fetchPaymentInfo callback
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
    {JPayment} = KD.remote.api
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
        KD.singleton("router").handleRoute "/Pricing"

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
            return  if KD.showError err
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
            KD.getSingleton('router').handleRoute '/Account/Subscriptions'
          else
            existingSubscription.plan = plan
            @confirmReactivation existingSubscription, (err, subscription) =>
              return KD.showError err  if err
              @emit "SubscriptionReactivated", subscription
        else if createAccount
          { cardFirstName: firstName, cardLastName: lastName } = billing
          { JUser } = KD.remote.api
          JUser.convert { firstName, lastName, email }, (err) =>
            return KD.showError err  if err
            JUser.logout ->
        else
          @emit "SubscriptionCompleted"

        KD.singletons.dock.getView().show()
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
    if KD.getGroup()?.slug is "koding"
      return callback()  if KD.whoami().type isnt "registered"
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
    KD.getGroup().fetchSubscription callback

  fetchSubscriptionsWithPlans: (options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}

    KD.whoami().fetchPlansAndSubscriptions options, (err, plansAndSubs) =>
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

  canDebitPack: (options = {}, callback = noop) ->
    {subscriptionTag, packTag, multiplyFactor} = options
    multiplyFactor ?= 1

    return warn "missing parameters"  unless subscriptionTag or packTag

    @fetchActiveSubscription tags: subscriptionTag, (err, subscription) ->
      KD.remote.api.JPaymentPack.one tags: packTag, (err, pack) ->
        subscription.checkUsage pack, multiplyFactor, callback
