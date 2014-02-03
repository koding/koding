class PricingAppController extends KDViewController

  handler = (callback) ->
    KD.singleton('appManager').open 'Pricing', callback

  KD.registerAppClass this,
    name                : "Pricing"
    routes              :
      "/:name?/Pricing" : ->
        (KD.getSingleton "router").handleRoute "/Pricing/Developer"

      "/:name?/Pricing/:section": ({params:{section}}) ->
        handler (app) ->
          {productForm} = app
          switch section
            when "Developer" then productForm.showDeveloperPlan()
            when "Team"      then productForm.showTeamPlan()
            else (KD.getSingleton "router").handleRoute "/Pricing/Developer"

      "/:name?/Pricing/CreateGroup": ->
        KD.remote.api.JGroupPlan.hasGroupCredit (err, hasCredit) ->
          if hasCredit
            handler (app) ->
              app.getView().showGroupForm()
          else
            (KD.getSingleton "router").handleRoute "/Pricing/Enterprise"

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView
      params        : options.params
      cssClass      : "content-page pricing"

    super options, data

    @productForm = new PricingProductForm
    @getView().addWorkflow workflow = KD.singleton("paymentController").createUpgradeWorkflow {@productForm}

  selectPlan: (tag, options) ->
    @productForm.selectPlan tag, options
