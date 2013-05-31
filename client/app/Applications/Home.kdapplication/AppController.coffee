class HomeAppController extends AppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"
    hiddenHandle : yes
    behavior     : "hideTabs"

  constructor:(options = {}, data)->
    # options.view    = new HomeMainView

    {entryPoint} = KD.config

    Konstructor = if entryPoint and entryPoint.type is 'group' then GroupHomeView else HomeAppView

    options.view    = new Konstructor
      cssClass      : "content-page home"
      domId         : "content-page-home"
      entryPoint    : entryPoint
    options.appInfo =
      name          : "Home"

    super options,data

  loadView:(mainView)->

  createContentDisplayWithOptions:(options, callback)->
    {model, route, query} = options

    controller = @getSingleton 'contentDisplayController'
    switch route
      when 'About'
        contentDisplay = new AboutView
        controller.emit 'ContentDisplayWantsToBeShown', contentDisplay
        callback contentDisplay
