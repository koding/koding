class PricingAppController extends KDViewController

  KD.registerAppClass this, name : 'Pricing'

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView
      params        : options.params
      cssClass      : "content-page pricing"

    super options, data
    @getView().createBreadcrumb()
    @createProductForm()

  createProductForm: ->
    view = @getView()
    @productForm.destroy()  if @productForm and not @productForm.isDestroyed
    @productForm = new PricingProductForm
      name : 'plan'

    workflow = KD.singleton("paymentController").createUpgradeWorkflow {@productForm}
    workflow.on "SubscriptionTransitionCompleted", view.bound "createGroup"

    view.setWorkflow workflow

    @productForm.on "PlanSelected", (plan, options) =>
      view.breadcrumb.showPlan plan, options
      view.addGroupForm()  if "custom-plan" in plan.tags

  selectPlan: (tag, options) ->
    @productForm.selectPlan tag, options
