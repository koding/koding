class PricingAppController extends KDViewController

  KD.registerAppClass this,
    name         : "Pricing"
    route        : "/Pricing"
    multiple     : no
    openWith     : "forceNew"
    behavior     : "application"
    navItem      :
      title      : "Develop"

  createWorkflow: ->
    paymentController = KD.getSingleton 'paymentController'

    paymentController.createUpgradeWorkflow 'vm'


  constructor:(options = {}, data)->

    options.view = new PricingAppView
      params     : options.params
      workflow   : @createWorkflow()

    options.appInfo =
      title         : "Pricing"

    super options, data

  open:(path)->
    @getView().openPath path
