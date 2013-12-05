class PricingAppController extends KDViewController

  KD.registerAppClass this,
    name         : "Pricing"
    route        : "/Pricing"
    multiple     : no
    openWith     : "forceNew"
    behavior     : "application"
    navItem      :
      title      : "Develop"

  constructor:(options = {}, data)->

    options.view = new PricingAppView
      params     : options.params
      workflow   : @createWorkflow()

    options.appInfo =
      title         : "Pricing"

    super options, data

  createWorkflow: ->
    paymentController = KD.getSingleton 'paymentController'

    workflow = paymentController.createUpgradeWorkflow 'vm'

    workflow.on 'Finished', @bound 'showThankYou'

  showThankYou: ->
    @getView().showThankYou()