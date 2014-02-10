class PaymentController extends KDController

  fetchPaymentMethods: (callback) ->

    { dash } = Bongo

    methods = null
    preferredPaymentMethod = null
    appStorage = new AppStorage 'Account', '1.0'
    queue = [

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
      @updatePaymentInfo paymentMethodId, updatedPaymentInfo, (err, savedPaymentInfo) =>
        if err
          modal.emit 'FormValidationFailed'
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

  updatePaymentInfo: (paymentMethodId, paymentMethod, callback) ->

    { JPayment } = KD.remote.api

    JPayment.setPaymentInfo paymentMethodId, paymentMethod, callback

  createPaymentInfoModal: -> new PaymentFormModal

  createUpgradeForm: (tag, options = {}) ->
    buyPacksButton = new KDButtonView
      cssClass     : "buy-packs"
      style        : "solid green medium"
      title        : "Buy Resource Packs"
      callback     : ->
        @parent.emit "Cancel"
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

    productForm or= @createUpgradeForm tag, options
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

          return workflow.emit 'GroupCreationFailed'  if err

          workflow.emit 'SubscriptionTransitionCompleted', subscription
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
          KD.singletons.dock.getView().show()
        else if createAccount
          { cardFirstName: firstName, cardLastName: lastName } = billing
          { JUser } = KD.remote.api
          JUser.convert { firstName, lastName, email }, (err) ->
            JUser.logout()
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
    { planApi } = planOptions

    throw new Error "Must provide a plan API!"  unless planApi?

    options = {
      planOptions
      promotionType
      paymentMethodId
      planCode: plan.planCode
    }

    planApi.subscribe options, callback

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

  fetchSubscriptionsWithPlans: (options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}

    KD.whoami().fetchPlansAndSubscriptions options, (err, plansAndSubs) =>
      return callback err  if err

      { subscriptions } = @groupPlansBySubscription plansAndSubs

      callback null, subscriptions

  fetchGroupSubscription: (callback) ->
    KD.getGroup().fetchSubscription callback

  groupPlansBySubscription: (plansAndSubscriptions = {}) ->

    { plans, subscriptions } = plansAndSubscriptions

    plansByCode = plans.reduce( (memo, plan) ->
      memo[plan.planCode] = plan
      memo
    , {})

    for subscription in subscriptions
      subscription.plan = plansByCode[subscription.planCode]

    { plans, subscriptions }

  debitWrapper: (options = {}, callback) ->
    options.fn = @debitSubscription.bind this
    @_runWrapper options, callback

  creditWrapper: (options = {}, callback) ->
    options.fn = @creditSubscription.bind this
    @_runWrapper options, callback

  _runWrapper: (options, callback) ->
    {fn, subscriptionTag, packTag} = options

    kallback (err, subscription) =>
      return callback err  if err
      if subscription
        KD.remote.api.JPaymentPack.one tags: packTag, (err, pack) =>
          return callback err  if err
          fn subscription, pack, (err, nonce) =>
            return callback err  if err
            callback null, nonce
      else
        callback()

    group = KD.getGroup()
    if group.slug is "koding"
      @fetchSubscriptionsWithPlans tags: [subscriptionTag], (err, subscriptions) =>
        return  if KD.showError err
        [subscription] = subscriptions
        kallback subscription
    else
      @fetchGroupSubscription kallback
