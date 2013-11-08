class VmProductForm extends JView

  createUpgradeForm: ->
    (KD.getSingleton 'paymentController').createUpgradeForm 'vm'

  checkUsageLimits: (plan) ->
    console.log 'we need to check the usage limits for this plan', plan

  setState: (state) ->
    switch state
      when 'upgrade'  then @upgradeForm.show()
      when 'choice'   then console.log 'they need to choose their plan'

  setCurrentPlans: (plans) ->
    @currentPlans = plans
    switch plans.length
      when 0
        @setState 'upgrade'
      when 1
        @checkUsageLimits plans[0]
      else
        @setState 'choice'

  viewAppended: -> @prepareProductForm()

  prepareProductForm: ->
    @upgradeForm = @createUpgradeForm()
    @upgradeForm.on 'PlanSelected', (plan) =>
      @emit 'DataCollected', { plan }
    @addSubView @upgradeForm
    @upgradeForm.hide()