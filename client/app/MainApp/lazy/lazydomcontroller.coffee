class LazyDomController extends KDController

  fetchCurrentGroup = (callback)->
    {groupEntryPoint} = KD.config
    KD.remote.api.JGroup.one slug: groupEntryPoint, (err, group)=>
      error err if err
      if err then new KDNotificationView
        title : "An error occured, please try again"
      else unless group?
        new KDNotificationView title : "No such group!"
      else callback group

  constructor:->
    super

    @groupViewsAdded   = no
    @profileViewsAdded = no

    @mainController = @getSingleton 'mainController'

    @mainController.on 'FrameworkIsReady', =>
      @emit "staticControllerIsReady"
      if @userEnteredFromGroup()
        @addGroupViews()

        # FIXME this is just a wip snip for showing the banner
        @utils.wait 3000, =>
          @landingView?.show()

      else if @userEnteredFromProfile()
        @addProfileViews()

      log "landing views put"

      if @landingView
        @landingView.bindTransitionEnd()

        @on "landingViewIsHidden", ->
          $('body').removeClass 'landing'
          $('body').addClass 'koding'

        @on "landingViewIsShown", ->
          $('body').addClass 'landing'
          $('body').removeClass 'koding'


  isLandingPageVisible:-> $('body').is('.landing')

  hideLandingPage:(callback)->

    return unless @landingView

    @landingView.once "transitionend", (event)=>
      # @landingView.hide()
      @emit "landingViewIsHidden"
      callback? event

    {groupSummary} = @mainController.mainViewController.getView()
    @landingView.$().css marginTop : -window.innerHeight

  showLandingPage:(callback = noop)->

    return unless @landingView

    {contentPanel, groupSummary} = @mainController.mainViewController.getView()

    @landingView.once "transitionend", (event)=>
      contentPanel.unsetClass "no-anim"
      @emit "landingViewIsShown"
      callback? event

    # @landingView.show()
    @landingView.$().css marginTop : 0
    contentPanel.setClass "no-anim"
    contentPanel.setClass "social"

  userEnteredFromGroup:-> (KD.config.entryPoint? and KD.config.entryPoint.type == "group")

  userEnteredFromProfile:-> (KD.config.entryPoint? and KD.config.entryPoint.type == "profile")

  addGroupViews:->

    return if @groupViewsAdded
    @groupViewsAdded         = yes
    @staticGroupController   = new StaticGroupController
    {@landingView}           = @staticGroupController

  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded       = yes
    @staticProfileController = new StaticProfileController
    {@landingView}           = @staticProfileController

  openPath:(path)-> @getSingleton('router').handleRoute path

  handleNavigationItemClick:(item, event)->

    mc = @getSingleton 'mainController'
    {action, path} = item
    {loginScreen, mainViewController}    = mc
    {groupEntryPoint, profileEntryPoint} = KD.config

    return @openPath(path) if path

    switch action
      when 'login'
        loginScreen.animateToForm 'login'
      when 'register'
        loginScreen.animateToForm 'register'
      when 'request' then @requestAccess()
      when 'join-group'
        fetchCurrentGroup (group)=>
          group.join (err, response)=>
            error err if err
            if err then new KDNotificationView
              title : "An error occured, please try again"
            else
              new KDNotificationView
                title : "You've successfully joined to group!"
              @openPath "/#{groupEntryPoint}/Activity"

      when 'logout'
        mainViewController.getView().hide()
        @openPath '/Logout'

      # when 'activity'
      #   @getSingleton('staticProfileController').emit 'ActivityLinkClicked', -> item.loader.hide()

      # when 'about'
      #   @getSingleton('staticProfileController').emit 'AboutLinkClicked', -> item.loader.hide()

      # when 'home'
      #   @getSingleton('staticProfileController').emit 'HomeLinkClicked', -> item.loader.hide()

  requestAccess:->
    {loginScreen} = @getSingleton('mainController')
    {groupEntryPoint, profileEntryPoint} = KD.config

    if KD.isLoggedIn()
      fetchCurrentGroup (group)=>
        @getSingleton('groupsController').openPrivateGroup group
    else
      @getSingleton('mainController').loginScreen.animateToForm 'lr'
