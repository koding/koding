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

    @group             = null
    @mainController    = @getSingleton "mainController"
    @lazyDomController = @getSingleton "lazyDomController"
    {@entryPoint} = KD.config

    @reviveViews()
    @attachListeners()
    @on 'GroupSummaryListenersAttached', =>
      @checkGroupUserRelation()

    @registerSingleton 'staticGroupController', @, yes

  parseMenuItems :(callback)->
    menuItems = []
    titles = @groupContentView.$('.has-markdown>span.data>h1')
    for title in titles
      menuItems.push
        title : $(title).text()
        line : 0
    callback menuItems


  reviveViews :->

    @landingView = new KDView
      lazyDomId : 'static-landing-page'

    @landingView.listenWindowResize()
    @landingView._windowDidResize = =>
      {innerHeight} = window
      @landingView.setClass 'resizing-noanim'
      @landingView.setHeight innerHeight

      @utils.killWait @wait
      @wait = @utils.wait 200, =>
          @landingView.unsetClass 'resizing-noanim'

      if parseInt(@landingView.$().css("margin-top"),10) < 0
        @landingView.$().css marginTop : -innerHeight

    @groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    @groupTitleView = new KDView
      lazyDomId : 'group-title'

    @groupReadmeView = new KDView
      lazyDomId : 'group-readme'


    @groupContentView = new KDScrollView
      lazyDomId : 'group-landing-content'
      scroll    : (event)=>
        if @groupContentView.getScrollTop() > 57
          @landingNav.setClass "in"
        else
          @landingNav.unsetClass "in"

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

    @landingView.addSubView @landingNav = new KDCustomHTMLView
      tagName   : 'nav'
      lazyDomId : "landing-page-nav"
      click     : (event)=>
        if $(event.target).is('h2')
          @groupContentView.scrollTo duration : 300

    @buttonWrapper = new KDCustomHTMLView
      cssClass : "button-wrapper"

    @buttonWrapper.addSubView @userButtonBar = new StaticUserButtonBar

    @utils.defer =>
      groupLogoView.setClass 'animate'
      @landingView._windowDidResize()

    @createGroupNavigation()

  createGroupNavigation:->

    @parseMenuItems (items)=>

      flyingNavController  = new KDListViewController
        view         : new KDListView
          itemClass  : GroupLandingNavItem
          wrapper    : no
          scrollView : no
          type       : "group-landing-nav"

      flyingNav = flyingNavController.getListView()
      flyingNav.on "viewAppended", ->
        flyingNavController.instantiateListItems items.slice()

      @landingNav.addSubView flyingNavController.getListView()

      flyingNav.on "groupLandingNavItemClicked", @bound "scrollToTitle"

      titles       = @groupContentView.$('.has-markdown h1')
      if titles.length
        scrollHeight = @groupContentView.getScrollHeight()
        positionTop  = $(titles[titles.length-1]).position().top
        surplus      = scrollHeight - positionTop - 50
        marginBottom = window.innerHeight - surplus

        if marginBottom > 0
          @groupContentView.$('.content-item-scroll-wrapper').css {marginBottom}

  scrollToTitle:(itemData)->

    titles = @groupContentView.$('.has-markdown h1')

    for title in titles when $(title).text() is itemData.title
      @groupContentView.scrollTo
        top      : $(title).position().top - 50
        duration : 300
      break

  checkGroupUserRelation:->
    statuses = KD.config.roles
    if 'member' in statuses or 'admin' in statuses
      isAdmin = 'admin' in statuses
      @emit roleEventMap.member, isAdmin
    else
      @emit roleEventMap[statuses.first]

  removeBackground:->
    @groupTitleView.$().css backgroundImage : "none"
    @groupTitleView.$().css backgroundColor : "#ffffff"

  setBackground:(type,val)->
    if type in ['defaultImage','customImage']
      @groupSplitView.unsetClass 'vignette'
      @groupContentView.$().css backgroundColor : 'white'
      @utils.wait 200, =>
        @groupTitleView.$().css backgroundImage : "url(#{val})"
        @utils.wait 200, =>
          @groupContentView.$().css backgroundColor : 'transparent'
    else
      @groupSplitView.setClass 'vignette'
      @groupTitleView.$().css backgroundImage : "none"
      @groupTitleView.$().css backgroundColor : "#{val}"

  attachListeners:->

    @on "status.pending", @bound "decoratePendingStatus"
    @on "status.member",  @bound "decorateMemberStatus"
    @on "status.guest",   @bound "decorateGuestStatus"

    @on "AccessIsRequested", @bound "decoratePendingStatus"

    @mainController.on "accountChanged.to.loggedOut", =>
      @buttonWrapper.destroySubViews()

    @mainController.on "accountChanged.to.loggedIn", =>
      @checkGroupUserRelation()

  decoratePendingStatus:->

    @requestButton?.hide()
    @pendingButton = new CustomLinkView
      title    : "REQUEST PENDING"
      cssClass : "request-pending"
      icon     : {}
      click    : (event)=> event.preventDefault()

    @buttonWrapper.addSubView @pendingButton

  decorateMemberStatus:(isAdmin)->

    open = new CustomLinkView
      title    : "Open group"
      cssClass : "open"
      icon     : {}
      click    : (event)=>
        event.preventDefault()
        @openGroup()

    @requestButton?.hide()
    @buttonWrapper.addSubView open

    if isAdmin
      # dashboard = new CustomLinkView
      #   title    : "Go to Dashboard"
      #   cssClass : "customize"
      #   icon     : {}
      #   click    : (event)=>
      #     event.preventDefault()
      #     @lazyDomController.openPath "/#{@entryPoint}/Activity"

      # @buttonWrapper.addSubView dashboard

      @buttonWrapper.addSubView config = new CustomLinkView
        title    : "Customize"
        cssClass : "customize"
        icon     : {}
        click    : (event)=>
          event.preventDefault()
          if @groupContentWrapperView.$().hasClass  'edit'
            @groupContentWrapperView.unsetClass     'hide-front'
            @utils.wait 200, =>
              @groupContentWrapperView.unsetClass   'edit'
          else
            # scroll only if there is a distance to scroll
            unless @groupContentView.$().scrollTop() is 0
              @groupContentView.$().animate
                scrollTop : 0
              ,200, 'swing', =>
                @groupContentWrapperView.setClass   'edit'
                @utils.wait 800, =>
                  @groupContentWrapperView.setClass 'hide-front'
            else
              # immediately flip otherwise
              @groupContentWrapperView.setClass     'edit'

      groupConfigView = new KDView
        lazyDomId : 'group-config'

      groupConfigView.addSubView new StaticGroupCustomizeView
        delegate : @
      ,@getData()

    @openGroup()

  openGroup:->
    router = KD.getSingleton 'router'
    if router.getCurrentPath() is @entryPoint.slug
      @lazyDomController.openPath "/Activity", {@entryPoint}
    else
      @lazyDomController.hideLandingPage()
    KD.utils.wait 600, -> $('#main-koding-loader').hide()

  decorateGuestStatus:->

    @requestButton?.hide()

    @requestButton = new CustomLinkView
      title    : "Request Access"
      cssClass : "request"
      icon     : {}
      click    : (event)=>
        event.preventDefault()
        @lazyDomController.requestAccess()

    @buttonWrapper.addSubView @requestButton

    @listenToNewMember()

    if KD.isLoggedIn()
      KD.remote.api.JMembershipPolicy.byGroupSlug @entryPoint.slug, (err, policy)=>
        if err then console.warn err
        else unless policy?.approvalEnabled
          @requestButton.destroy()
          @requestButton = new CustomLinkView
            title    : "Join Group"
            cssClass : "join"
            icon     : {}
            click    : (event)=>
              event.preventDefault()
              @lazyDomController.handleNavigationItemClick
                action  : 'join-group'

          @buttonWrapper.addSubView @requestButton

  listenToNewMember:->
    cb = (group)=>
      group.fetchMembershipStatuses (err, statuses)=>
        if err then warn err
        else if statuses.length
          if 'member' in statuses or 'admin' in statuses
            return
          group.on 'MemberAdded', =>
            unless @requestApproved
              group.fetchMyRoles (err,roles)=>
                unless err or roles?.length is 0
                  if 'member' in roles
                    @pendingButton?.hide()
                    @requestButton?.hide()
                    @decorateMemberStatus no
                    @requestApproved = yes

    if @group then cb @group
    else @fetchGroup (err, group)-> cb group

  fetchGroup:(callback)->
    KD.remote.cacheable @entryPoint.slug, (err, groups, name)=>
      if err then callback err
      else if groups?.first
        @group = groups.first
        callback null, @group


class GroupLandingNavItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    or= "a"
    options.attributes   =
      href               : "#"

    super options, data

  viewAppended: JView::viewAppended

  click:(event)->
    event.preventDefault()
    @getDelegate().emit "groupLandingNavItemClicked", @getData()

  pistachio:-> "{{ #(title)}}"
