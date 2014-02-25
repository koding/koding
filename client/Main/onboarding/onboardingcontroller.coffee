class OnboardingController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @items = {}
    @fetchItems()

    mainController = KD.getSingleton "mainController"
    mainController.on "accountChanged.to.loggedIn", @bound "fetchItems"

  fetchItems: ->
    return  unless KD.isLoggedIn()
    query = partialType: "ONBOARDING"
    KD.remote.api.JCustomPartials.some query, {}, (err, onboarding) =>
      @items[item.name] = item.partial  for item in onboarding
      @bindOnboardingEvents()

  bindOnboardingEvents: ->
    appManager = KD.getSingleton "appManager"
    appManager.on "AppCreated", (app) =>
      KD.utils.wait 3000, =>
        appName    = app.getOptions().name
        onboarding = @items[appName]
        return  unless onboarding?.items.length

        new OnboardingViewController { app }, onboarding
