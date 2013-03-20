class StaticGroupController extends KDController

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

    @checkGroupUserRelation()
    @attachListeners()

  checkGroupUserRelation:->

    KD.remote.cacheable @groupEntryPoint, (err, group, name)=>
      if err then warn err
      else if group?.first
        group.first.fetchMembershipStatuses (err, status)=>
          if err then warn err
          else
            log status
            switch status
              when "invitation-pending"  then @emit "status.pending"
              when "invitation-sent"     then @emit "status.action-required"
              when "invitation-declined" then @emit "status.declined"
              when "member","admin"      then @emit "status.member"
              when "guest"               then @emit "status.guest"



  attachListeners:->

    @on "status.pending", @bound "decoratePendingStatus"
    @on "status.member",  @bound "decorateMemberStatus"
    @on "status.guest",   @bound "decorateGuestStatus"

  decoratePendingStatus:->

    @groupTitleView.addSubView new KDButtonView
      title    : "REQUEST PENDING"
      cssClass : "editor-button"

  decorateMemberStatus:->

    @groupTitleView.addSubView new KDButtonView
      title    : "Open group"
      cssClass : "editor-button"
      callback : =>
        @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"

  decorateGuestStatus:->

    @groupTitleView.addSubView button = new KDButtonView
      title    : "Request Access"
      cssClass : "editor-button"
      callback : =>
        @lazyDomController.requestAccess()

    if KD.isLoggedIn()
      KD.remote.api.JMembershipPolicy.byGroupSlug @groupEntryPoint, (err, policy)=>
        if err then console.warn err
        else unless policy?.approvalEnabled
          log 'geldiik mi?'
          button.setTitle "Join Group"
          button.setCallback =>
            @lazyDomController.openPath "/#{@groupEntryPoint}/Activity"
