class StaticGroupController extends KDController

  roleEventMap =
    "guest"               : "status.guest"
    "member"              : "status.member"
    "invitation-pending"  : "status.pending"
    "invitation-sent"     : "status.action-required"
    "invitation-declined" : "status.declined"

  constructor:->

    super

    @mainController    = @getSingleton "mainController"
    @lazyDomController = @getSingleton "lazyDomController"
    {@groupEntryPoint} = KD.config

    @landingView = new KDView
      lazyDomId : 'static-landing-page'

    @landingView.listenWindowResize()
    @landingView._windowDidResize = =>
      {innerHeight} = window
      @landingView.setHeight innerHeight
      groupContentView.setHeight innerHeight - @groupTitleView.getHeight()

    groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    @groupTitleView = new KDView
      lazyDomId : 'group-title'

    @groupTitleView.addSubView @buttonWrapper = new KDCustomHTMLView
      cssClass : "button-wrapper"

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

    @utils.defer =>
      groupLogoView.setClass 'animate'
      @landingView._windowDidResize()

    @checkGroupUserRelation()
    @attachListeners()

  checkGroupUserRelation:->

    KD.remote.cacheable @groupEntryPoint, (err, groups, name)=>
      if err then warn err
      else if groups?.first
        groups.first.fetchMembershipStatuses (err, statuses)=>
          if err then warn err
          else if statuses.length
            if "member" in statuses or (isAdmin = "admin" in statuses)
              @emit roleEventMap.member, isAdmin
            else
              @emit roleEventMap[statuses.first]

  attachListeners:->

    @on "status.pending", @bound "decoratePendingStatus"
    @on "status.member",  @bound "decorateMemberStatus"
    @on "status.guest",   @bound "decorateGuestStatus"

    @mainController.on "accountChanged.to.loggedOut", =>
      @buttonWrapper.destroySubViews()

    @mainController.on "accountChanged.to.loggedIn", =>
      @checkGroupUserRelation()

  decoratePendingStatus:->

    button = new KDButtonView
      title    : "REQUEST PENDING"
      cssClass : "editor-button"

    @buttonWrapper.addSubView button

  decorateMemberStatus:(isAdmin)->

    open = new KDButtonView
      title    : "Open group"
      cssClass : "editor-button"
      callback : =>
        @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

    @buttonWrapper.addSubView open

    dashboard = new KDButtonView
      title    : "Go to Dashboard"
      cssClass : "editor-button"
      callback : =>
        @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

    @buttonWrapper.addSubView dashboard

  decorateGuestStatus:->

    button = new KDButtonView
      title    : "Request Access"
      cssClass : "editor-button"
      callback : =>
        @lazyDomController.requestAccess()

    @buttonWrapper.addSubView button

    if KD.isLoggedIn()
      KD.remote.api.JMembershipPolicy.byGroupSlug @groupEntryPoint, (err, policy)=>
        if err then console.warn err
        else unless policy?.approvalEnabled
          button.setTitle "Join Group"
          button.setCallback =>
            @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"
