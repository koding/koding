class LazyDomController extends KDController

  constructor:->
    super

    @groupViewsAdded   = no
    @profileViewsAdded = no

    @mainController = @getSingleton 'mainController'

    @mainController.on 'AppIsReady', =>
      if @userEnteredFromGroup()
        @addGroupViews()
        # @switchGroupState isLoggedIn
      else if @userEnteredFromProfile()
        @addProfileViews()

      landingPageSideBar = new LandingPageSideBar

  userEnteredFromGroup:-> KD.config.groupEntryPoint?

  userEnteredFromProfile:-> KD.config.profileEntryPoint?

  switchGroupState:(isLoggedIn)->

    {groupEntryPoint} = KD.config

    loginLink = new GroupsLandingPageButton {groupEntryPoint}, {}

    if isLoggedIn and groupEntryPoint?
      KD.whoami().fetchGroupRoles groupEntryPoint, (err, roles)->
        if err then console.warn err
        else if roles.length
          loginLink.setState { isMember: yes, roles }
        else
          {JMembershipPolicy} = KD.remote.api
          JMembershipPolicy.byGroupSlug groupEntryPoint,
            (err, policy)->
              if err then console.warn err
              else if policy?
                loginLink.setState {
                  isMember        : no
                  approvalEnabled : policy.approvalEnabled
                }
              else
                loginLink.setState {
                  isMember        : no
                  isPublic        : yes
                }
    else
      @utils.defer -> loginLink.setState { isLoggedIn: no }

    loginLink.appendToSelector '.group-login-buttons'

  addGroupViews:->

    return if @groupViewsAdded
    @groupViewsAdded = yes

    groupLandingView = new KDView
      lazyDomId : 'group-landing'

    groupLandingView.listenWindowResize()
    groupLandingView._windowDidResize = =>
      groupLandingView.setHeight window.innerHeight
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

        groupLandingView.setClass 'group-fading'
        @utils.wait 1100, => groupLandingView.setClass 'group-hidden'

    groupLogoView.setY groupLandingView.getHeight()-42

    @utils.wait =>
      groupLogoView.setClass 'animate'
      groupLandingView._windowDidResize()


  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded = yes

    new StaticProfileController
