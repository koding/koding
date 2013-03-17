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

    @landingView = new KDView
      lazyDomId : 'static-landing-page'

    @landingView.listenWindowResize()
    @landingView._windowDidResize = =>
      @landingView.setHeight window.innerHeight
      groupContentView.setHeight window.innerHeight-groupTitleView.getHeight()

    groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    groupTitleView = new KDView
      lazyDomId : 'group-title'

    groupContentView = new KDView
      lazyDomId : 'group-loading-content'

    groupPersonalWrapperView = new KDView
      lazyDomId : 'group-personal-wrapper'
      cssClass  : 'slideable'
      click :(event)=>
        unless event.target.tagName is 'A'
          @mainController.loginScreen.unsetClass 'landed'

    groupLogoView = new KDView
      lazyDomId: 'group-koding-logo'
      click :=>
        groupPersonalWrapperView.setClass 'slide-down'
        groupContentWrapperView.setClass 'slide-down'
        groupLogoView.setClass 'top'

        @landingView.setClass 'group-fading'
        @utils.wait 1100, => @landingView.setClass 'group-hidden'

    groupLogoView.setY @landingView.getHeight()-42

    @utils.wait =>
      groupLogoView.setClass 'animate'
      @landingView._windowDidResize()


  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded      = yes
    staticProfileController = new StaticProfileController
    @landingView            = staticProfileController.profileLandingView
