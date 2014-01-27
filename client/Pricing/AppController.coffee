class PricingAppController extends KDViewController

  handler = (callback)->
    KD.singleton('appManager').open 'Pricing', callback

  KD.registerAppClass this,
    name                         : "Pricing"
    routes                       :
      "/:name?/Pricing"          : -> KD.singletons.router.handleRoute '/Pricing/Developer'
      "/:name?/Pricing/:section" : ({params:{section}})->
        handler (app)->
          app.customPlanForm.hide()
          app.userPlanForm.hide()
          switch section
            when 'Developer'
              app.userPlanForm.show()
            when 'Enterprise'
              app.customPlanForm.show()

  constructor: (options = {}, data) ->

    options.view = new PricingAppView
      params     : options.params
      cssClass   : "content-page pricing"

    options.appInfo = title: "Pricing"

    super options, data

    @userPlanForm   = new UserPlanForm
      cssClass  : 'hidden'
      unitPrice : 20

    @customPlanForm = new CustomPlanForm
      cssClass          : 'hidden'
      userUnitPrice     : 5
      resourceUnitPrice : 20

    productForm = new KDView

    productForm.addSubView @userPlanForm
    productForm.forwardEvent @userPlanForm, "PlanSelected"

    productForm.addSubView @customPlanForm
    productForm.forwardEvent @customPlanForm, "PlanSelected"

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

    workflow.on "Finished", (data, subscription) ->
