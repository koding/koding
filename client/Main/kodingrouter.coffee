class KodingRouter extends KDRouter

  @registerStaticEmitter()

  nicenames =
    StartTab  : 'Develop'

  getSectionName =(model)->
    sectionName = nicenames[model.bongo_.constructorName]
    if sectionName? then " - #{sectionName}" else ''

  constructor:(@defaultRoute)->

    @defaultRoute or= location.pathname + location.search
    @openRoutes     = {}
    @openRoutesById = {}
    KD.getSingleton('contentDisplayController')
      .on 'ContentDisplayIsDestroyed', @bound 'cleanupRoute'
    @ready = no
    KD.getSingleton('mainController').once 'AccountChanged', =>
      @ready = yes
      @utils.defer => @emit 'ready'

    super()

    KodingRouter.emit 'RouterReady', this

    @addRoutes getRoutes.call this

    @on 'AlreadyHere', -> log "You're already here!"

  listen:->
    super
    unless @userRoute
      {entryPoint} = KD.config
      @handleRoute @defaultRoute,{
        shouldPushState: yes
        replaceState: yes
        entryPoint
      }

  notFound =(route)->
    # defer this so that notFound can be called before the constructor.
    @utils.defer => @addRoute route, ->
      console.warn "Contract warning: shared route #{route} is not implemented."

  handleRoute:(route, options={})->

    # InternalApps Fetcher
    appManager = KD.getSingleton 'appManager'
    frags      = route.split '/'
    name       = frags[1] or ''
    name       = if name is 'Develop' and frags.length > 2 then frags[2] else name

    log 'handlingRoute', route, 'for the', name, 'app'
    if appManager.checkAppAvailability name
      log 'couldn\'t found', name
      return KodingAppsController.putAppScript name, (err)=>
        log 'Router: loaded', name
        return warn err  if err
        KD.utils.defer => @handleRoute route, options

    {entryPoint} = options
    if entryPoint?.slug? and entryPoint.type is "group"
      entrySlug = "/" + entryPoint.slug
      # if incoming route is prefixed with groupname or entrySlug is the route
      # also we dont want koding as group name
      if not ///^#{entrySlug}///.test(route) and entrySlug isnt '/koding'
        route =  entrySlug + route

    super route, options

  handleRoot =->
    # don't load the root content when we're just consuming a hash fragment
    unless location.hash.length
      KD.getSingleton("contentDisplayController").hideAllContentDisplays()
      {entryPoint} = KD.config
      if KD.isLoggedIn()
        @handleRoute @userRoute or @getDefaultRoute(), {replaceState: yes, entryPoint}
      else
        @handleRoute @getDefaultRoute(), {entryPoint}

  cleanupRoute:(contentDisplay)->
    delete @openRoutes[@openRoutesById[contentDisplay.id]]

  openSection:(app, group, query)->
    return @once 'ready', @openSection.bind this, arguments...  unless @ready

    KD.getSingleton('groupsController').changeGroup group, (err)=>
      if err then new KDNotificationView title: err.message
      else
        # temp fix for not showing homepage to loggedin users
        # app = 'Activity' if app is 'Home' and KD.isLoggedIn()

        @setPageTitle nicenames[app] ? app
        appManager  = KD.getSingleton "appManager"
        handleQuery = appManager.tell.bind appManager, app, "handleQuery", query

        appManager.once "AppCreated", handleQuery  unless appWasOpen = appManager.get app

        appManager.open app, (appInstance)=>
          appInstance.setOption "initialRoute", @getCurrentPath()

        handleQuery()  if appWasOpen

  handleNotFound:(route)->

    status_404 = =>
      KDRouter::handleNotFound.call this, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    KD.remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target? then status_404()
      else status_301 target

  getDefaultRoute:-> if KD.isLoggedIn() then '/Activity' else '/'

  setPageTitle:(title="Koding")-> document.title = Encoder.htmlDecode title

  getContentTitle:(model)->
    {JAccount, JStatusUpdate, JGroup} = KD.remote.api
    @utils.shortenText(
      switch model.constructor
        when JAccount       then  KD.utils.getFullnameFromAccount model
        when JStatusUpdate  then  model.body
        when JGroup         then  model.title
        else                      "#{model.title}#{getSectionName model}"
    , maxLength: 100) # max char length of the title

  openContent:(name, section, models, route, query, passOptions=no)->
    method   = 'createContentDisplay'
    [models] = models  if Array.isArray models

    @setPageTitle @getContentTitle models

    # HK: with passOptions false an application only gets the information
    # 'hey open content' with this model. But some applications require
    # more information such as the route. Unfortunately we would need to
    # refactor a lot legacy. For now we do this new thing opt-in
    if passOptions
      method += 'WithOptions'
      options = {model:models, route, query}

    callback = =>
      KD.getSingleton("appManager").tell section, method, options ? models, (contentDisplay) =>
        routeWithoutParams = route.split('?')[0]
        @openRoutes[routeWithoutParams] = contentDisplay
        @openRoutesById[contentDisplay.id] = routeWithoutParams
        contentDisplay.emit 'handleQuery', query

    groupsController = KD.getSingleton('groupsController')
    currentGroup = groupsController.getCurrentGroup()

    # change group if necessary
    unless currentGroup
      groupName = if section is "Groups" then name else "koding"
      groupsController.changeGroup groupName, (err) =>
        KD.showError err if err
        callback()
    else
      callback()

  loadContent:(name, section, slug, route, query, passOptions)->
    routeWithoutParams = route.split('?')[0]

    groupName = if section is "Groups" then name else "koding"
    KD.getSingleton('groupsController').changeGroup groupName, (err) =>
      KD.showError err if err
      onSuccess = (models)=>
        @openContent name, section, models, route, query, passOptions
      onError   = (err)=>
        KD.showError err
        @handleNotFound route

      if name and not slug
        KD.remote.cacheable name, (err, models)=>
          if models?
          then onSuccess models
          else onError err
      else
        # TEMP FIX: getting rid of the leading slash for the post slugs
        slashlessSlug = routeWithoutParams.slice(1)
        KD.remote.api.JName.one { name: slashlessSlug }, (err, jName)=>
          if err then onError err
          else if jName?
            models = []
            jName.slugs.forEach (aSlug, i)=>
              {constructorName, usedAsPath} = aSlug
              selector = {}
              konstructor = KD.remote.api[constructorName]
              selector[usedAsPath] = aSlug.slug
              selector.group = aSlug.group if aSlug.group
              konstructor?.one selector, (err, model)=>
                return onError err if err?
                if model
                  models[i] = model
                  if models.length is jName.slugs.length
                    onSuccess models
          else onError()

  createContentDisplayHandler:(section, passOptions=no)->
    ({params:{name, slug}, query}, models, route)=>

      route = name unless route
      contentDisplay = @openRoutes[route.split('?')[0]]
      if contentDisplay?
        KD.getSingleton("contentDisplayController")
          .hideAllContentDisplays contentDisplay
        contentDisplay.emit 'handleQuery', query
      else if models?
        @openContent name, section, models, route, query, passOptions
      else
        @loadContent name, section, slug, route, query, passOptions

  createStaticContentDisplayHandler:(section, passOptions=no)->
    (params, models, route)=>

      contentDisplay = @openRoutes[route]
      if contentDisplay?
        KD.getSingleton("contentDisplayController")
          .hideAllContentDisplays contentDisplay
      else
        @openContent null, section, models, route, null, passOptions

  clear:(route, replaceState=yes)->
    unless route
      {entryPoint} = KD.config
      route =
        if KD.isLoggedIn() and entryPoint?.type is 'group' and entryPoint?.slug?
           "/#{KD.config.entryPoint?.slug}"
        else '/'
    super route, replaceState

  getRoutes =->
    mainController = KD.getSingleton 'mainController'
    clear = @bound 'clear'

    getAction = (formName) -> switch formName
      when 'login'    then 'log in'
      when 'register' then 'register'

    animateToForm = (formName, force = no) ->
      { mainTabView } = KD.getSingleton 'mainView'
      appsAreOpen = mainTabView.getVisibleHandles?().length > 0
      if not force and formName in ['login', 'register'] and appsAreOpen
        ok = no
        modal = KDModalView.confirm
          title: "Are you sure you want to #{getAction formName}?"
          description: "You will lose your work"
          ok: callback: ->
            ok = yes
            modal.destroy()
            animateToForm formName, yes
        modal.once 'KDObjectWillBeDestroyed', -> clear()  if not ok
      else
        mainController.loginScreen.animateToForm formName

    requireLogin =(fn)->
      mainController.ready ->
        if KD.isLoggedIn() then __utils.defer fn
        else clear()

    requireLogout =(fn)->
      mainController.ready ->
        unless KD.isLoggedIn() then __utils.defer fn
        else clear()

    createSectionHandler = (sec)=>
      ({params:{name, slug}, query})=>
        @openSection slug or sec, name, query

    createContentHandler       = @bound 'createContentDisplayHandler'
    createStaticContentHandler = @bound 'createStaticContentDisplayHandler'

    routes =

      '/'                      : handleRoot
      ''                       : handleRoot
      # '/Home'                : handleRoot
      '/About'                 : createSectionHandler 'Activity'

      '/Landing/:page'         : noop
      '/R/:username'           : noop

      # verbs
      '/:name?/Login'          : ({params:{name}})-> requireLogout -> animateToForm 'login'
      '/:name?/Logout'         : ({params:{name}})-> requireLogin  -> mainController.doLogout()
      '/:name?/Redeem'         : ({params:{name}})-> requireLogin  -> animateToForm 'redeem'
      '/:name?/Register'       : ({params:{name}})-> requireLogout -> animateToForm 'register'
      '/:name?/Recover'        : ({params:{name}})-> requireLogout -> animateToForm 'recover'
      '/:name?/ResendToken'    : ({params:{name}})-> requireLogout -> animateToForm 'resendEmail'

      # content
      '/:name?/Topics/:slug'   : createContentHandler 'Topics'
      '/:name?/Activity/:slug' : createContentHandler 'Activity'
      '/:name?/Apps/:slug'     : createContentHandler 'Apps'

      '/:name/Groups'          : createSectionHandler 'Groups'
      '/:name/Followers'       : createContentHandler 'Members', yes
      '/:name/Following'       : createContentHandler 'Members', yes
      '/:name/Likes'           : createContentHandler 'Members', yes

      '/:name?/Recover/:recoveryToken': ({params:{recoveryToken}})->
        return  if recoveryToken is 'Password'

        recoveryToken = decodeURIComponent recoveryToken
        {JPasswordRecovery} = KD.remote.api
        JPasswordRecovery.validate recoveryToken, (err, isValid)=>
          if err or !isValid
            unless KD.isLoggedIn()
              new KDNotificationView
                title   : 'Something went wrong.'
                content : err?.message or """
                  That doesn't seem to be a valid recovery token!
                  """
          else
            mainController.loginScreen.headBannerShowRecovery recoveryToken
          @clear "/"

      '/:name?/Invitation/:inviteCode': ({params:{inviteCode}})=>
        inviteCode = decodeURIComponent inviteCode
        if KD.isLoggedIn()
          mainController.loginScreen.doRedeem {inviteCode}
          @handleRoute '/', entryPoint: KD.config.entryPoint
        else KD.remote.api.JInvitation.byCode inviteCode, (err, invite)=>
          if err or !invite? or invite.status not in ['active','sent']
            unless KD.isLoggedIn()
              if err then error err
              new KDNotificationView
                title: 'Invalid invitation code!'
          else
            mainController.loginScreen.headBannerShowInvitation invite
          @clear "/"

      '/:name?/Verify/:confirmationToken': ({params:{confirmationToken}})->
        confirmationToken = decodeURIComponent confirmationToken
        KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)=>
          if err
            error err
            KD.showError err
          else
            new KDNotificationView
              title: "Thanks for confirming your email address!"
          @clear()

      '/:name?/InviteFriends': ->
        if KD.isLoggedIn()
          @handleRoute '/Activity', entryPoint: KD.config.entryPoint
          if KD.introView
            KD.introView.once "transitionend", ->
              KD.utils.wait 1200, ->
                new ReferrerModal
          else
            new ReferrerModal
        else
          @handleRoute '/Login'

      '/member/:username': ({params:{username}})->
        @handleRoute "/#{username}", replaceState: yes

      '/:name?/Unsubscribe/:token/:email/:opt?':
        ({params:{token, email, opt}})->
          opt   = decodeURIComponent opt
          email = decodeURIComponent email
          token = decodeURIComponent token
          (
            if opt is 'email'
            then KD.remote.api.JMail
            else KD.remote.api.JMailNotification
          ).unsubscribeWithId token, email, opt, (err, content)=>
            if err or not content
              title   = 'An error occured'
              content = 'Invalid unsubscribe token provided.'
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
            @clear()

      # top level names
      '/:name':do->

        open = (routeInfo, model)->

          switch model?.bongo_?.constructorName
            when 'JAccount'
              (createContentHandler 'Members') routeInfo, [model]
            when 'JGroup'
              (createSectionHandler 'Activity') routeInfo, model
            else
              @handleNotFound routeInfo.params.name

        (routeInfo, state, route)->

          if state?
            open.call this, routeInfo, state

          else
            KD.remote.cacheable routeInfo.params.name, (err, models, name)=>
              model = models.first  if models
              open.call this, routeInfo, model

    routes
