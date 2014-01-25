class PricingAppController extends KDViewController

  # FIXME: obviously, remove this once this is prod ready - SY
  if true or location.hostname is "localhost"
    KD.registerAppClass this,
      name         : "Pricing"
      route        : "/Pricing"

  constructor: (options = {}, data) ->
    options.view = new PricingAppView
      params     : options.params
      cssClass   : "content-page pricing"

    options.appInfo = title: "Pricing"

    super options, data

    userPlanForm = new UserPlanForm unitPrice: 20
    customPlanForm = new CustomPlanForm userUnitPrice: 5, resourceUnitPrice: 20

    productForm = new KDView

    productForm.addSubView userPlanForm
    productForm.forwardEvent userPlanForm, "PlanSelected"

    productForm.addSubView customPlanForm
    productForm.forwardEvent customPlanForm, "PlanSelected"

    @getView().addWorkflow workflow = KD.singleton("paymentController").createUpgradeWorkflow
      productForm: productForm

    # # TODO : remove after test
    # workflow.emit "Finished",
    #     productData          :
    #       planOptions        :
    #         userQuantity     :  5 # arabada
    #         resourceQuantity : 15 # evde
    #       plan               :
    #         tags             : ["custom-plan"]

    workflow.on "Finished", (data, subscription) ->
