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

    # @navLinks = []
    # @currentFacets = []

    @reviveViews()

    @checkGroupUserRelation()
    @attachListeners()

    @registerSingleton 'staticGroupController', @, yes


  reviveViews :->

    @landingView = new KDView
      lazyDomId : 'static-landing-page'

    @landingView.listenWindowResize()
    @landingView._windowDidResize = =>
      {innerHeight} = window
      @landingView.setHeight innerHeight

    @groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    @groupTitleView = new KDView
      lazyDomId : 'group-title'
      click     : =>
        # @activityListWrapper.hide()
        @groupReadmeView.show()

    @groupReadmeView = new KDView
      lazyDomId : 'group-readme'

    @buttonWrapper = new KDCustomHTMLView
      cssClass : "button-wrapper"
      lazyDomId : "group-button-wrapper"

    @groupContentView = new KDView
      lazyDomId : 'group-loading-content'

    @groupSplitView = new KDView
      lazyDomId : 'group-splitview'

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
        @groupContentWrapperView.setClass 'slide-down'
        groupLogoView.setClass 'top'

        @landingView.setClass 'group-fading'
        @utils.wait 1100, => @landingView.setClass 'group-hidden'

    groupLogoView.setY @landingView.getHeight()-42

    @buttonWrapper.addSubView userButtonBar = new StaticUserButtonBar

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
            if "member" in statuses or "admin" in statuses
              isAdmin = 'admin' in statuses
              @emit roleEventMap.member, isAdmin
            else
              @emit roleEventMap[statuses.first]

  removeBackground:->
    @groupContentWrapperView.$().css backgroundImage : "none"
    @groupContentWrapperView.$().css backgroundColor : "#ffffff"

  setBackground:(type,val)->
    if type in ['defaultImage','customImage']
      @groupSplitView.unsetClass 'vignette'
      @groupContentView.$().css backgroundColor : 'white'
      @utils.wait 200, =>
        @groupContentWrapperView.$().css backgroundImage : "url(#{val})"
        @utils.wait 200, =>
          @groupContentView.$().css backgroundColor : 'transparent'
    else
      @groupSplitView.setClass 'vignette'
      @groupContentWrapperView.$().css backgroundImage : "none"
      @groupContentWrapperView.$().css backgroundColor : "#{val}"

  attachListeners:->

    @on "status.pending", @bound "decoratePendingStatus"
    @on "status.member",  @bound "decorateMemberStatus"
    @on "status.guest",   @bound "decorateGuestStatus"

    @mainController.on "accountChanged.to.loggedOut", =>
      @buttonWrapper.destroySubViews()

    @mainController.on "accountChanged.to.loggedIn", =>
      @checkGroupUserRelation()


    # @on 'StaticProfileNavLinkClicked', (facets,type,callback=->)=>

    #   facets = [facets] if 'string' is typeof facets
    #   @emit 'DecorateStaticNavLinks', CONTENT_TYPES, facets.first
    #   @currentFacets = facets
    #   appManager.tell 'Activity', 'fetchActivity',
    #     group : @groupEntryPoint
    #     facets : facets
    #     bypass : yes
    #   , (err, activities=[])=>
    #     @refreshActivities err, activities, facets, callback

  # refreshActivities:(err,activities,type,callback)->
  #   @groupReadmeView.hide()
  #   controller = @activityController
  #   controller.removeAllItems()

  #   facetPlural = constructorToPluralNameMap[@currentFacets[0]] or 'activity'

  #   controller.getOptions().noItemFoundWidget.updatePartial \
  #     "So far, no one has not posted any #{facetPlural} in this group"

  #   controller.listActivities activities
  #   controller.hideLazyLoader()
  #   @activityListWrapper.show()
  #   callback?()

  # appendActivities:(err,activities,callback)->
  #   @groupReadmeView.hide()
  #   controller = @activityController
  #   # controller.removeAllItems()
  #   controller.listActivities activities
  #   controller.hideLazyLoader()
  #   callback?()

  decoratePendingStatus:->

    link = new CustomLinkView
      title    : "REQUEST PENDING"
      cssClass : "request-pending"
      icon     : {}
      click    : (event)=> event.preventDefault()

    @buttonWrapper.addSubView link

  decorateMemberStatus:(isAdmin)->

    open = new CustomLinkView
      title    : "Open group"
      cssClass : "open"
      icon     : {}
      click    : (event)=>
        event.preventDefault()
        @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

    @buttonWrapper.addSubView open

    if isAdmin
      # dashboard = new CustomLinkView
      #   title    : "Go to Dashboard"
      #   cssClass : "customize"
      #   icon     : {}
      #   click    : (event)=>
      #     event.preventDefault()
      #     @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

      # @buttonWrapper.addSubView dashboard

      @buttonWrapper.addSubView config = new CustomLinkView
        title    : "Customize"
        cssClass : "customize"
        icon     : {}
        click    : (event)=>
          event.preventDefault()
          if @groupContentWrapperView.$().hasClass 'edit'
            @groupContentWrapperView.unsetClass 'edit'
          else @groupContentWrapperView.setClass 'edit'

      groupConfigView = new KDView
        lazyDomId : 'group-config'

      groupConfigView.addSubView new StaticGroupCustomizeView
        delegate : @
      ,@getData()



  decorateGuestStatus:->

    link = new CustomLinkView
      title    : "Request Access"
      cssClass : "request"
      icon     : {}
      click    : (event)=>
        event.preventDefault()
        @lazyDomController.requestAccess()

    @buttonWrapper.addSubView link

    if KD.isLoggedIn()
      KD.remote.api.JMembershipPolicy.byGroupSlug @groupEntryPoint, (err, policy)=>
        if err then console.warn err
        else unless policy?.approvalEnabled
          link.destroy()
          link = new CustomLinkView
            title    : "Join Group"
            cssClass : "join"
            icon     : {}
            click    : (event)=>
              event.preventDefault()
              @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

          @buttonWrapper.addSubView link
