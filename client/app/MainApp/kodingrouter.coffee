class KodingRouter extends KDRouter

  @registerStaticEmitter()

  nicenames = {
    StartTab  : 'Develop'
  }

  getSectionName =(model)->
    sectionName = nicenames[model.bongo_.constructorName]
    if sectionName? then " - #{sectionName}" else ''

  constructor:(@defaultRoute)->

    @openRoutes = {}
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
    @on 'Params', ({params, query})=>
      #@utils.defer => KD.getSingleton('groupsController').changeGroup params.name

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
        @setPageTitle nicenames[app] ? app
        appManager = KD.getSingleton "appManager"
        appManager.open app, (appInstance)=>
          appInstance.setOption "initialRoute", @getCurrentPath()
        appManager.tell app, 'handleQuery', query

  handleNotFound:(route)->

    status_404 = =>
      KDRouter::handleNotFound.call this, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    KD.remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target? then status_404()
      else status_301 target

  getDefaultRoute:-> '/Activity'

  setPageTitle:(title="Koding")-> document.title = Encoder.htmlDecode title

  getContentTitle:(model)->
    {JAccount, JStatusUpdate, JGroup} = KD.remote.api
    @utils.shortenText(
      switch model.constructor
        when JAccount       then "#{model.profile.firstName} #{model.profile.lastName}"
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

    KD.getSingleton("appManager").tell section, method, options ? models,
      (contentDisplay)=>
        routeWithoutParams = route.split('?')[0]
        @openRoutes[routeWithoutParams] = contentDisplay
        @openRoutesById[contentDisplay.id] = routeWithoutParams
        contentDisplay.emit 'handleQuery', query

  loadContent:(name, section, slug, route, query, passOptions)->
    routeWithoutParams = route.split('?')[0]
    # return log name, ">>>>>"

    onSuccess = (models)=> @openContent name, section, models, route, query, passOptions
    onError   = (err)=>
      new KDNotificationView title: err?.message or 'An unknown error has occured.'
      @handleNotFound route

    if name
      KD.remote.cacheable name or routeWithoutParams, (err, models)=>
        if models?
        then onSuccess models
        else onError err
    else
      KD.remote.api.JName.one {name: routeWithoutParams}, (err, jName)=>
        if err then onError err
        else if jName?
          models = []
          jName.slugs.forEach (aSlug, i)=>
            {constructorName, usedAsPath} = aSlug
            selector = {}
            konstructor = KD.remote.api[constructorName]
            selector[usedAsPath] = aSlug.slug
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
      if entryPoint?.type is 'group' and entryPoint?.slug?
        route = "/#{KD.config.entryPoint?.slug}"
      else
        route = '?'
    super route, replaceState

  getRoutes =->
    mainController = KD.getSingleton 'mainController'
    clear = @bound 'clear'

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

      '/'      : handleRoot
      ''       : handleRoot
      # '/About' : createStaticContentHandler 'Home', yes
      '/About' : createSectionHandler 'Activity'

      # verbs
      '/:name?/Login'     : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'login'
      '/:name?/Logout'    : ({params:{name}})->
        requireLogin  -> mainController.doLogout()
      '/:name?/Register'  : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'register'
      '/:name?/Join'      : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'join'
      '/:name?/Recover'   : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'recover'

      # apps
      '/:name?/Develop/:slug'           : createSectionHandler 'Develop'

      # content
      '/:name?/Topics/:slug'            : createContentHandler 'Topics'
      '/:name?/Activity/:slug'          : createContentHandler 'Activity'
      '/:name?/Apps/:slug'              : createContentHandler 'Apps'

      '/:name/Followers'                : createContentHandler 'Members', yes
      '/:name/Following'                : createContentHandler 'Members', yes
      '/:name/Likes'                    : createContentHandler 'Members', yes

      '/:name?/Recover/:recoveryToken': ({params:{recoveryToken}})->
        return  if recoveryToken is 'Password'

        recoveryToken = decodeURIComponent recoveryToken
        {JPasswordRecovery} = KD.remote.api
        JPasswordRecovery.validate recoveryToken, (err, isValid)=>
          if err or !isValid
            new KDNotificationView
              title   : 'Something went wrong.'
              content : err?.message or """
                That doesn't seem to be a valid recovery token!
                """
          else
            mainController.loginScreen.headBannerShowRecovery recoveryToken
          @clear()

      '/:name?/Invitation/:inviteToken': ({params:{inviteToken}})->
        inviteToken = decodeURIComponent inviteToken
        if KD.isLoggedIn()
          new KDNotificationView
            title: 'Could not redeem invitation because you are already logged in.'
        else KD.remote.api.JInvitation.byCode inviteToken, (err, invite)=>
          if err or !invite? or invite.status not in ['active','sent']
            if err then error err
            new KDNotificationView
              title: 'Invalid invitation code!'
          else
            mainController.loginScreen.headBannerShowInvitation invite
          @clear()

      '/:name?/Verify/:confirmationToken': ({params:{confirmationToken}})->
        confirmationToken = decodeURIComponent confirmationToken
        KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)=>
          location.replace '#'
          if err
            error err
            new KDNotificationView
              title: "Something went wrong, please try again later!"
          else
            new KDNotificationView
              title: "Thanks for confirming your email address!"
          @clear()

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

      # REFACTOR HERE! PUBLIC KEY SHOULDN'T BE SENT, TRY WITH A TOKEN
      '/:name?/KD/Register/:hostname/:key':
        ({params:{key, hostname}})->
          key = decodeURIComponent key
          hostname = decodeURIComponent hostname

          showModal = (title, content)=>
            modal = new KDModalView
              title        : title
              overlay      : yes
              cssClass     : "new-kdmodal"
              content      : "<div class='modalformline'>#{content}</div>"
              buttons      :
                "Close"    :
                  style    : "modal-clean-gray"
                  callback : (event)->
                    modal.destroy()
            @clear()

          if key.length isnt 64
            title = "Key is not valid!"
            content = """
            <p>
            You provided an invalid Koding Key. Please try with another one.
            You can renew your Koding key using <code>$ kd register renew</code> on command
            line interface.
            </p>
            """
            return showModal title, content

          KD.remote.api.JKodingKey.fetchByKey
            key: key
          , (err, kodingKey) =>
            unless kodingKey?.length
              KD.remote.api.JKodingKey.create {hostname, key}, (err, data)=>
                if err or not data
                  title   = 'An error occured'
                  content = """
                  <p>You provided an invalid Koding Key. Please try with another one.
                  You can renew your Koding key using <code>$ kd register renew</code> on command
                  line interface.</p>
                  """
                  log err
                else
                  title   = 'Host Connected!'
                  content = """
                  <p>You've connected your Koding Key! It will help you to use Koding command line interface
                  with more features!</p>
                  """
                showModal title, content
            else
              title   = "You've already connected the host!"
              content = """
              <p>You've already connected to Koding. If you want to renew your Koding key, you should
              run <code>$ kd register renew</code> on command line interface.</p>
              """
              showModal title, content
      # top level names
      '/:name':do->
        open =(routeInfo, model)->
          switch model?.bongo_?.constructorName
            when 'JAccount'
              (createContentHandler 'Members') routeInfo, [model]
            when 'JGroup'
              (createSectionHandler 'Activity') routeInfo, model
            else
              @handleNotFound routeInfo.params.name

        nameHandler =(routeInfo, state, route)->

          if state?
            open.call this, routeInfo, state

          else
            KD.remote.cacheable routeInfo.params.name, (err, [model], name)=>
              open.call this, routeInfo, model

    routes
