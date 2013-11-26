class VmProductForm extends FormWorkflow

  createUpgradeForm: ->
    (KD.getSingleton 'paymentController').createUpgradeForm 'vm', yes

  checkUsageLimits: (pack, callback) ->
    { subscription } = @collector.data
    return callback { message: 'no subscription' }  unless subscription?
    subscription.checkUsage pack, (err, usage) =>
      if err
        @collectData oldSubscription: subscription
        @clearData 'subscription'

      callback err, usage

  createPackChoiceForm: -> new PackChoiceForm
    title     : 'Choose your VM'
    itemClass : VmProductView

  setCurrentSubscriptions: (subscriptions) ->
    @currentSubscriptions = subscriptions
    switch subscriptions.length
      when 0
        @showForm 'upgrade'
      when 1
        [subscription] = subscriptions
        @collectData { subscription }
      else
        [subscription] = subscriptions
        @collectData { subscription }
        console.warn { message: 'User has multiple subscriptions', subscriptions }
        # @showForm 'choice'

  setContents: (type, contents) -> switch type
    when 'packs'
      (@getForm 'pack choice').setContents contents

  createChoiceForm: -> new KDView partial: 'this is a plan choice form'

  prepareWorkflow: ->
    @requireData [

      @any('subscription', 'plan')

      'pack'
    ]

    upgradeForm = @createUpgradeForm()
    upgradeForm.on 'PlanSelected', (plan) =>
      @collectData { plan }

    @addForm 'upgrade', upgradeForm, ['plan', 'subscription']

    packChoiceForm = @createPackChoiceForm()
    packChoiceForm.once 'Activated', => @emit 'PackOfferingRequested'

    packChoiceForm.on 'PackSelected', (pack) =>
      @checkUsageLimits pack, (err, usage) =>
        @collectData { pack }

    @addForm 'pack choice', packChoiceForm, ['pack']

    choiceForm = @createChoiceForm()
