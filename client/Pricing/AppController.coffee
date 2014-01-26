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

    productForm       = new KDView
    @resourcePackPlan = new ResourcePackPlan
    @customPlan       = new CustomPlan

    productForm.addSubView @resourcePackPlan
    productForm.forwardEvent @resourcePackPlan, "PlanSelected"

    productForm.addSubView @customPlan
    productForm.forwardEvent @customPlan, "PlanSelected"

    @getView().addWorkflow workflow = KD.singleton("paymentController").createUpgradeWorkflow
      productForm: productForm

    # TODO : remove after test
    # workflow.emit "Finished",
    #     productData          :
    #       planOptions        :
    #         userQuantity     :  5 # arabada
    #         resourceQuantity : 15 # evde
    #       plan               :
    #         tags             : ["custom-plan"]
