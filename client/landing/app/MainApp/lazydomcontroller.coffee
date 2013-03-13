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

    groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    new KDView
      lazyDomId : 'group-title'

    # new SplitViewWithOlderSiblings
    #   lazyDomId : 'group-splitview'
    #   parent : groupContentWrapperView

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

    @utils.wait => groupLogoView.setClass 'animate'

  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded = yes

    profileLandingView = new KDView
      lazyDomId : 'profile-landing'

    profileContentWrapperView = new KDView
      lazyDomId : 'profile-content-wrapper'
      cssClass : 'slideable'

    new KDView
      lazyDomId : 'profile-title'

    # new SplitViewWithOlderSiblings
    #   lazyDomId : 'profile-splitview'
    #   parent : profileContentWrapperView

    profilePersonalWrapperView = new KDView
      lazyDomId : 'profile-personal-wrapper'
      cssClass : 'slideable'

    profileLogoView = new KDView
      lazyDomId: 'profile-koding-logo'
      click :=>
        profilePersonalWrapperView.setClass 'slide-down'
        profileContentWrapperView.setClass 'slide-down'
        profileLogoView.setClass 'top'

        profileLandingView.setClass 'profile-fading'
        @utils.wait 1100, => profileLandingView.setClass 'profile-hidden'

    profileLogoView.setY profileLandingView.getHeight()-42

    @utils.wait => profileLogoView.setClass 'animate'

    KD.remote.cacheable KD.config.profileEntryPoint, (err, user, name)=>
      KD.remote.api.JBlogPost.some {originId : user.getId()}, {limit:5,sort:{'meta.createdAt':-1}}, (err,blogs)=>

        log err if err
        profileContentView = new KDListView
          lazyDomId : 'profile-content'
          itemClass : StaticBlogPostListItem
        , blogs

        profileContentListController = new KDListViewController
          view : profileContentView
        , blogs

        unless err
          profileContentView.$('.content-item').remove()

          profileContentView.on 'ItemWasAdded', (instance, index)->
            instance.viewAppended()

          profileContentListController.instantiateListItems blogs

    profileLandingView.listenWindowResize()
    profileLandingView._windowDidResize = =>
      profileLandingView?.setHeight window.outerHeight
