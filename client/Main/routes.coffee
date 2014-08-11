do ->

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  requireLogin = (fn)->
    {router} = KD.singletons
    if KD.isLoggedIn() then utils.defer fn else router.clear()

  requireLogout = (fn)->
    {router} = KD.singletons
    unless KD.isLoggedIn() then utils.defer fn else router.clear()

  handleRoot = ->
    # don't load the root content when we're just consuming a hash fragment
    unless location.hash.length

      {display, router} = KD.singletons
      {entryPoint}      = KD.config
      replaceState      = yes

      display.hideAllDisplays()

      if KD.isLoggedIn()
      then router.handleRoute router.userRoute or router.getDefaultRoute(), {replaceState, entryPoint}
      else router.handleRoute router.getDefaultRoute(), {entryPoint}

  routerReady = (fn)->
    {router} = KD.singletons
    if router then fn() else KDRouter.on 'RouterIsReady', fn

  createSectionHandler = (sec) ->
    routerReady ->
      ({params:{name, slug}, query}) ->
        {router} = KD.singletons
        router.openSection slug or sec, name, query

  createContentDisplayHandler = (section, passOptions = no) ->

    ({params:{name, slug}, query}, models, route)->

      {router} = KD.singletons
      route = name unless route
      contentDisplay = router.openRoutes[route.split('?')[0]]

      if contentDisplay?
        KD.singleton('display').hideAllDisplays contentDisplay
        contentDisplay.emit 'handleQuery', query
      else if models?
        router.openContent name, section, models, route, query, passOptions
      else
        router.loadContent name, section, slug, route, query, passOptions

  KD.registerRoutes 'KDMainApp',
    '/'                      : handleRoot
    ''                       : handleRoot
    '/R/:username'           : ({params:{username}})->
      KD.mixpanel "Visit referrer url, success", {username}
      # give a notification to tell that this is a referral link here - SY
      @handleRoute if KD.isLoggedIn() then "/Activity" else "/"
    '/:name?/Logout'         : ({params:{name}})->
      requireLogin ->
        {mainController} = KD.singletons
        mainController.doLogout()
    '/:name?/Topics/:slug'   : ({params:{name, slug}}) ->
      route = unless slug then "/Activity/Topic/#{slug}" else "/Activity"
      route = "#{name}/#{route}"  if name
      @handleRoute route
    '/:slug/:name' : ({params, query}, model, route) ->
      (createContentDisplayHandler 'Members') arguments...
    '/:name?/Invitation/:inviteCode': ({params:{inviteCode, name}})->
      @handleRoute "/Redeem/#{inviteCode}"
    '/:name?/InviteFriends': ->
      if KD.isLoggedIn()
        @handleRoute '/Activity', entryPoint: KD.config.entryPoint
        new ReferrerModal
      else @handleRoute '/Login'
    '/member/:username': ({params:{username}})->
      @handleRoute "/#{username}", replaceState: yes
    '/:name?/Unsubscribe/:token/:email/:opt?':
      ({params:{token, email, opt}})->
        {router} = KD.singletons
        opt      = decodeURIComponent opt
        email    = decodeURIComponent email
        token    = decodeURIComponent token
        (
          if opt is 'email'
          then KD.remote.api.JMail
          else KD.remote.api.JNotificationMailToken
        ).unsubscribeWithId token, email, opt, (err, content)->
          if err or not content
            title   = 'An error occurred'
            content = 'Invalid unsubscription token provided.'
            log err
          else
            title   = 'E-mail settings updated'

          modal = new KDModalView
            title        : title
            overlay      : yes
            cssClass     : 'new-kdmodal'
            content      : "<div class='modalformline'>#{content}</div>"
            buttons      :
              "Close"    :
                style    : 'modal-clean-gray'
                callback : -> modal.destroy()
          router.clear()

    "/:name?/Apps/:username/:app?": ({params:{username, name}})->

      if username[0] is username[0].toUpperCase()
        app      = username
        username = name
        KD.remote.api.JNewApp.one slug:"#{username}/Apps/#{app}", (err, app)->
          if not err and app
            KodingAppsController.runExternalApp app, dontUseRouter:yes

    # top level names
    '/:name': do ->

      open = (routeInfo, model)->

        switch model?.bongo_?.constructorName
          when 'JAccount'
            (createContentDisplayHandler 'Members') routeInfo, [model]
          when 'JGroup'
            (createSectionHandler 'Activity') routeInfo, model
          when 'JNewApp'
            KodingAppsController.runApprovedApp model, dontUseRouter:yes
          else
            @handleNotFound routeInfo.params.name

      (routeInfo, state, route)->

        if state?
          open.call this, routeInfo, state

        else
          KD.remote.cacheable routeInfo.params.name, (err, models, name)=>
            if models?
            then open.call this, routeInfo, models.first
            else @handleNotFound routeInfo.params.name


# FIXME ~ GG
# animateToForm = (formName, force = no) ->
#   { mainTabView } = KD.getSingleton 'mainView'
#   appsAreOpen = mainTabView.getVisibleHandles?().length > 0
#   if not force and formName in ['login', 'register'] and appsAreOpen
#     ok = no
#     modal = KDModalView.confirm
#       title: "Are you sure you want to #{getAction formName}?"
#       description: "You will lose your work"
#       ok: callback: ->
#         ok = yes
#         modal.destroy()
#         animateToForm formName, yes
#     modal.once 'KDObjectWillBeDestroyed', -> clear()  if not ok
#   else
#     warn "FIXME Add tell to Login app ~ GG @ kodingrouter", formName
#     # mainController.loginScreen.animateToForm formName
