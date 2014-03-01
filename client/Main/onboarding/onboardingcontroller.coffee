class OnboardingController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    mainController = KD.getSingleton "mainController"
    @appStorage    = KD.getSingleton("appStorageController").storage "OnboardingStatus", "1.0.0"

    @fetchItems()  if KD.isLoggedIn()

    mainController.on "accountChanged.to.loggedIn", @bound "fetchItems"

    @on "OnboardingShown", (slug) =>
      @appStorage.setValue slug, yes

  fetchItems: ->
    query = partialType: "ONBOARDING"
    KD.remote.api.JCustomPartials.some query, {}, (err, onboardings) =>

      for data in onboardings when data.partial
        appName = data.partial.app
        @onboardings[appName] = []  unless @onboardings[appName]
        @onboardings[appName].push data

      @appStorage.fetchStorage (storage) =>
        @bindOnboardingEvents()

  bindOnboardingEvents: ->
    appManager = KD.getSingleton "appManager"
    appManager.on "AppCreated", (app) =>
      appName = app.getOptions().name
      return unless @onboardings[appName]

      KD.utils.wait 3000, =>
        onboardings = @onboardings[appName]
        onboarding  = null

        for item in onboardings
          slug    = KD.utils.slugify KD.utils.curry appName, item.name
          isShown = @appStorage.getValue slug

          unless isShown
            onboarding = item
            break

        return unless onboarding?.partial.items?.length

        new OnboardingViewController { app, slug, delegate: this }, onboarding.partial
