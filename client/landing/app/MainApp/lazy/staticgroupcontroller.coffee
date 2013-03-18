class StaticGroupController extends KDController

  constructor:->

    super

    @mainController = @getSingleton "mainController"

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

    {@groupEntryPoint} = KD.config

    log @groupEntryPoint, "<- we're here in this very group! as such, farewell!"

    KD.remote.cacheable @groupEntryPoint, (err, group, name)=>
      if err then warn err
      else if group?.first
        group.first.fetchMembershipStatus (err, status)=>
          if err then warn err
          else
            log status, "<- this is the status of the fellow member which is currently lookin at this very page!"
            switch status
              when "invitation-pending"
                @emit "status.pending"
              when "invitation-declined as such"
                log "TBDL"
                @emit "status.declined"
              when "member"
                @emit "status.member"



  attachListeners:->

    @on "status.*", -> log "wildcard in events"

    @on "status.pending", @bound "decoratePendingStatus"
    @on "status.member",  @bound "decorateMemberStatus"



  decoratePendingStatus:->

    @groupTitleView.addSubView new KDButtonView
      title    : "REQUEST PENDING"
      cssClass : "clean-gray fr"
      disabled : yes

  decorateMemberStatus:->

    @groupTitleView.addSubView new KDButtonView
      title    : "Open"
      cssClass : "cupid-green fr"
      callback : ->
        log "anca buraya gelince"
