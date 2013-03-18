class LazyDomController extends KDController

  constructor:->
    super

    @groupViewsAdded   = no
    @profileViewsAdded = no

    @mainController = @getSingleton 'mainController'

    @mainController.on 'AppIsReady', =>
      if @userEnteredFromGroup()
        @addGroupViews()
      else if @userEnteredFromProfile()
        @addProfileViews()

      landingPageSideBar = new LandingPageSideBar

  hideLandingPage:->

    if @landingView
      @landingView.setClass "out"
      # FIXME: GG
      # @landingView.on "transtionEnd", @landingView.bound "hide"
      @utils.wait 600, @landingView.bound "hide"

  showLandingPage:(callback = noop)->

    if @landingView
      @landingView.show()
      @landingView.unsetClass "out"
      @utils.wait 600, callback

  userEnteredFromGroup:-> KD.config.groupEntryPoint?

  userEnteredFromProfile:-> KD.config.profileEntryPoint?

  addGroupViews:->

    return if @groupViewsAdded
    @groupViewsAdded = yes
    staticGroupController   = new StaticGroupController
    {@landingView}          = staticGroupController

  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded      = yes
    staticProfileController = new StaticProfileController
    @landingView            = staticProfileController.profileLandingView
