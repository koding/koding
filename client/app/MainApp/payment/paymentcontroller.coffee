class PaymentController extends KDController

  fetchPaymentMethods: (callback) ->

    { dash } = Bongo

    methods = null
    preferredPaymentMethod = null
    appStorage = new AppStorage 'Account', '1.0'
    queue = [

      -> appStorage.fetchStorage (err) ->
        preferredPaymentMethod = appStorage.getValue 'preferredPaymentMethod'
        queue.fin err

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
        return callback err  if err
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

  createUpgradeForm: (tag, forceUpgrade = no) ->

    { dash } = Bongo

    { JPaymentPlan } = KD.remote.api

    form = new PlanUpgradeForm { tag }

    JPaymentPlan.fetchPlans tag, (err, plans) =>
      return  if KD.showError err

      queue = plans.map (plan) -> ->
        plan.fetchProducts (err, products) ->
          return  if KD.showError err

          plan.childProducts = products
          queue.fin()

      subscription = null
      queue.push =>
        @fetchSubscriptionsWithPlans ['vm'], (err, [subscription_]) ->
          subscription = subscription_
          queue.fin()

      dash queue, ->
        form.setPlans plans
        form.setCurrentSubscription subscription, forceUpgrade  if subscription

    return form

  createUpgradeWorkflow: (tag, forceUpgrade = no) ->
    upgradeForm = @createUpgradeForm tag, forceUpgrade

    workflow = new PaymentWorkflow
      productForm: upgradeForm
      confirmForm: new PlanUpgradeConfirmForm

    upgradeForm
      .on 'PlanSelected', (plan) ->
        workflow.collectData productData: { plan }
      .on 'CurrentSubscriptionSet', (oldSubscription) ->
        workflow.collectData { oldSubscription }

    workflow
      .on('DataCollected', @bound 'transitionSubscription')
    
      .enter()

    workflow

  transitionSubscription: (formData) ->
    { productData, oldSubscription } = formData
    { plan:{ planCode }} = productData
    oldSubscription.transitionTo planCode, (err) ->
      debugger

  debitSubscription: (subscription, pack, callback) ->
    subscription.debit pack, (err, nonce) =>
      return  if KD.showError err

      @emit 'SubscriptionDebited', subscription

      callback null, nonce

  fetchSubscriptionsWithPlans: (tags, callback) ->
    [callback, tags] = [tags, callback]  unless callback

    KD.whoami().fetchPlansAndSubscriptions tags, (err, plansAndSubs) =>
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
