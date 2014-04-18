class TeamPlan extends DeveloperPlan

  handleBuy: ->
    @buyNow.showLoader()
    {paymentController, router} = KD.singletons

    paymentController.fetchActiveSubscription ["team-plan"], (err, subscription) =>
      return KD.showError err  if err and err.code isnt "no subscription"
      size  = @plans[@planIndex].size
      @emit "CurrentSubscriptionSet", subscription  if subscription
      @emit "PlanSelected", "tp#{size}", planApi: KD.remote.api.JResourcePlan

  setPlans: ->
    # [N]x = [Nx2] CPU + [Nx2]GB Ram + [Nx10]GB Disk + [Nx10] Total VM + [N] Always On (devrim's forumla)
    @planIndex = 0
    @plans     = [
      { size: 10,  cpu: 20,   ram: 20,   disk: 100,  alwaysOn: 10,  totalVMs: 100,  price: 299  }
      { size: 25,  cpu: 50,   ram: 50,   disk: 250,  alwaysOn: 25,  totalVMs: 250,  price: 749  }
      { size: 50,  cpu: 100,  ram: 100,  disk: 500,  alwaysOn: 50,  totalVMs: 500,  price: 1499 }
      { size: 75,  cpu: 150,  ram: 150,  disk: 750,  alwaysOn: 75,  totalVMs: 750,  price: 2249 }
      { size: 100, cpu: 200,  ram: 200,  disk: 1000, alwaysOn: 100, totalVMs: 1000, price: 2999 }
    ]

  getCountLabel: (value) ->
    {amountSuffix} = @slider.getOptions()
    {size}         = @plans[value]
    return "#{size}#{amountSuffix} <span class='plan-size-label'>for #{size} people</span>"

  getLabels: (index) ->
    plan = @plans[index]
    return {
      title  : "#{plan.size}x Resource Pack"
      desc   : "$#{plan.price}/Month"
      button : "BUY NOW"
    }
