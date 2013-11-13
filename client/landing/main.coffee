class LandingAppView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass    = "landingapp-view"
    options.pageClass or= LandingView
    super options, data

  viewAppended: ->
    @addSubView pageContainer = new KDView cssClass: "page-container"
    pageClass = @getOptions().pageClass
    pageContainer.addSubView new pageClass if pageClass

  @classMap:
    spaceship: SpaceshipLandingPage

KD.landingAppView = new LandingAppView
  pageClass       : LandingAppView.classMap[window.landingOptions.page]

KD.landingAppView.appendToDomBody()
