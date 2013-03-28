class StaticGroupController extends KDController

  CONTENT_TYPES = [
    'CBlogPostActivity','CStatusActivity','CCodeSnipActivity',
    'CDiscussionActivity', 'CTutorialActivity'
  ]

  constructorToPluralNameMap =
    'CStatusActivity'     : 'Status Updates'
    'CBlogPostActivity'   : 'Blog Posts'
    'CCodeSnipActivity'   : 'Code Snippets'
    'CDiscussionActivity' : 'Discussions'
    'CTutorialActivity'   : 'Tutorials'

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

    @navLinks = []
    @currentFacets = []

    @reviveViews()

    @checkGroupUserRelation()
    @attachListeners()


  reviveViews :->

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

    groupKodingLogo = new KDView
      lazyDomId : 'landing-page-logo'
      tooltip   :
        title   : "Click here to see this group on Koding"
      click     : =>
        if KD.isLoggedIn()
          @lazyDomController.hideLandingPage()
        else
          @mainController.loginScreen.animateToForm 'login'

    @landingView.groupLogo = new KDCustomHTMLView
      tagName   : "h3"
      lazyDomId : "group-logo"
      # cssClass  : "out"
      click     : => @getSingleton('lazyDomController').showLandingPage()

    @groupTitleView = new KDView
      lazyDomId : 'group-title'
      click     : =>
        @activityListWrapper.hide()
        @groupReadmeView.show()

    @groupReadmeView = new KDView
      lazyDomId : 'group-readme'

    @groupTitleView.addSubView @buttonWrapper = new KDCustomHTMLView
      cssClass : "button-wrapper"

    groupContentView = new KDView
      lazyDomId : 'group-loading-content'

    groupPersonalWrapperView = new KDView
      lazyDomId : 'group-personal-wrapper'
      cssClass  : 'slideable'
      click :(event)=>
        if event.target.id is 'group-personal-wrapper'
          @mainController.emit "landingSidebarClicked"

    groupLogoView = new KDView
      lazyDomId: 'group-koding-logo'
      click :=>
        groupPersonalWrapperView.setClass 'slide-down'
        groupContentWrapperView.setClass 'slide-down'
        groupLogoView.setClass 'top'

        @landingView.setClass 'group-fading'
        @utils.wait 1100, => @landingView.setClass 'group-hidden'

    groupLogoView.setY @landingView.getHeight()-42

    for type in CONTENT_TYPES
      @navLinks[type] = new StaticNavLink
        delegate  : @
        lazyDomId : type

    @groupContentLinks = new KDView
      lazyDomId : 'group-content-links'

    @activityController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView
      viewOptions       :
        cssClass        : 'group-activity-content activity-related'
      showHeader        : no

      noItemFoundWidget : new KDCustomHTMLView
        cssClass : "lazy-loader"
        partial  : "So far, this group does not have this kind of activity."

      noMoreItemFoundWidget : new KDCustomHTMLView
        cssClass : "lazy-loader"
        partial  : "There is no more activity."

    @activityListWrapper = @activityController.getView()
    groupContentView.addSubView @activityListWrapper

    @activityListWrapper.hide()

    @activityController.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        group     : @groupEntryPoint
        facets    : @currentFacets
        to        : @activityController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err,activities=[])=>
        @appendActivities err, activities, =>

    for type in CONTENT_TYPES
      @navLinks[type] = new StaticNavLink
        delegate  : @
        lazyDomId : type

    @utils.defer =>
      groupLogoView.setClass 'animate'
      @landingView._windowDidResize()


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


    @on 'StaticProfileNavLinkClicked', (facets,type,callback=->)=>

      facets = [facets] if 'string' is typeof facets
      @emit 'DecorateStaticNavLinks', CONTENT_TYPES, facets.first
      @currentFacets = facets
      appManager.tell 'Activity', 'fetchActivity',
        group : @groupEntryPoint
        facets : facets
        bypass : yes
      , (err, activities=[])=>
        @refreshActivities err, activities, facets, callback

  refreshActivities:(err,activities,type,callback)->
    @groupReadmeView.hide()
    controller = @activityController
    controller.removeAllItems()

    facetPlural = constructorToPluralNameMap[@currentFacets[0]] or 'activity'

    controller.getOptions().noItemFoundWidget.updatePartial \
      "So far, no one has not posted any #{facetPlural} in this group"

    controller.listActivities activities
    controller.hideLazyLoader()
    @activityListWrapper.show()
    callback?()

  appendActivities:(err,activities,callback)->
    @groupReadmeView.hide()
    controller = @activityController
    # controller.removeAllItems()
    controller.listActivities activities
    controller.hideLazyLoader()
    callback?()

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
