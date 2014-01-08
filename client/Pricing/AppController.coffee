class PricingAppController extends KDViewController

  # FIXME: obviously, remove this once this is prod ready - SY
  if location.hostname is "localhost"
    KD.registerAppClass this,
      name         : "Pricing"
      route        : "/Pricing"

  constructor:(options = {}, data)->

    options.view = new PricingAppView
      params     : options.params
      workflow   : @createWorkflow()
      cssClass   : "content-page pricing"

    options.appInfo =
      title         : "Pricing"

    super options, data

  createWorkflow: ->
    paymentController = KD.getSingleton 'paymentController'

    workflow = paymentController.createUpgradeWorkflow 'vm'

    workflow.on 'Finished', =>
      @getView().showThankYou workflow.getData()

    workflow.on 'Cancel', => @getView().showCancellation()