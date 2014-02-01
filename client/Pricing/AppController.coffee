class PricingAppController extends KDViewController

  handler = (callback)->
    KD.singleton('appManager').open 'Pricing', callback

  KD.registerAppClass this,
    name                         : "Pricing"
    routes                       :
      "/:name?/Pricing"          : ->
        (KD.getSingleton 'router').handleRoute '/Pricing/Developer'
      "/:name?/Pricing/:section" : ({params:{section}})->
        handler (app)->
          app.resourcePackPlan.hide()
          app.customPlan.hide()
          switch section
            when 'Developer'
              app.resourcePackPlan.show()
            when 'Enterprise'
              app.customPlan.show()
            else
              (KD.getSingleton 'router').handleRoute '/Pricing'
      '/:name?/Pricing/CreateGroup': ->
        { JGroupPlan } = KD.remote.api

        JGroupPlan.hasGroupCredit (err, hasCredit) ->
          if hasCredit
            handler (app) ->
              app.getView().showGroupCreateForm()
          else
            (KD.getSingleton 'router').handleRoute '/Pricing/Enterprise'

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView
      params        : options.params
      cssClass      : "content-page pricing"

    super options, data

    @productForm      = new KDView
    @resourcePackPlan = new ResourcePackPlan cssClass: "hidden"
    @customPlan       = new CustomPlan cssClass: "hidden"

    @productForm.addSubView @resourcePackPlan
    @resourcePackPlan.on "PlanSelected", @bound "selectPlan"

    @productForm.addSubView @customPlan
    @customPlan.on "PlanSelected", @bound "selectPlan"

    @getView().addWorkflow workflow = KD.singleton("paymentController").createUpgradeWorkflow {@productForm}

  selectPlan: (tag, options) ->
    KD.remote.api.JPaymentPlan.one tags: $in: [tag], (err, plan) =>
      return  if KD.showError err
      @productForm.emit "PlanSelected", plan, options
