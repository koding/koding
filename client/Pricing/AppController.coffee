class PricingAppController extends KDViewController

  KD.registerAppClass this,
    name  : "Pricing"
    route : "/:name?/Pricing"

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

    # TODO : remove after test
    # workflow.emit "Finished",
    #     productData          :
    #       planOptions        :
    #         userQuantity     :  5 # arabada
    #         resourceQuantity : 15 # evde
    #       plan               :
    #         tags             : ["custom-plan"]
