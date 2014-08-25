class KodingRouter extends KDRouter

  constructor: (@defaultRoute) ->

    @breadcrumb = []
    @defaultRoute or= location.pathname + location.search
    @openRoutes     = {}
    @openRoutesById = {}
    KD.singleton('display').on 'DisplayIsDestroyed', @bound 'cleanupRoute'

    super()

    @on 'AlreadyHere', -> log "You're already here!"


  listen: ->

    super

    return if @userRoute


    KD.utils.defer =>
      @handleRoute @defaultRoute,
        shouldPushState : yes
        replaceState    : yes
        entryPoint      : KD.config.entryPoint


  handleRoute: (route, options = {}) ->

    @breadcrumb.push route

    entryPoint = options.entryPoint or KD.config.entryPoint
    frags      = route.split("?")[0].split "/"

    [_root, _slug, _content, _extra] = frags

    if _slug is entryPoint?.slug
      name = if _content is 'Apps' and _extra? then _extra else _content
    else
      name = _slug

    appManager = KD.getSingleton 'appManager'
    if appManager.isAppInternal name
      return KodingAppsController.loadInternalApp name, (err)=>
        return warn err  if err
        KD.utils.defer => @handleRoute route, options

    if entryPoint?.slug and entryPoint.type is "group"
      entrySlug = "/" + entryPoint.slug
      # if incoming route is prefixed with groupname or entrySlug is the route
      # also we dont want koding as group name
      if not ///^#{entrySlug}///.test(route) and entrySlug isnt '/koding'
        route =  entrySlug + route

    super route, options

  cleanupRoute: (contentDisplay) ->

    delete @openRoutes[@openRoutesById[contentDisplay.id]]

  openSection: (app, group, query) ->

    {appManager} = KD.singletons
    handleQuery = appManager.tell.bind appManager, app, "handleQuery", query

    appManager.once "AppCreated", handleQuery  unless appWasOpen = appManager.get app
    appManager.open app

    handleQuery()  if appWasOpen

  handleNotFound: (route) ->

    status_404 = KDRouter::handleNotFound.bind this, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    KD.remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target?
      then status_404()
      else status_301 target

  getDefaultRoute: -> if KD.isLoggedIn() then '/IDE' else '/Home'

  setPageTitle: (title = 'Koding') -> document.title = Encoder.htmlDecode title

  openContent : (name, section, models, route, query, passOptions=no) ->
    method   = 'createContentDisplay'
    [models] = models  if Array.isArray models

    # HK: with passOptions false an application only gets the information
    # 'hey open content' with this model. But some applications require
    # more information such as the route. Unfortunately we would need to
    # refactor a lot legacy. For now we do this new thing opt-in
    if passOptions
      method += 'WithOptions'
      options = {model:models, route, query}

    callback = =>
      KD.getSingleton("appManager").tell section, method, options ? models, (contentDisplay) =>
        unless contentDisplay
          console.warn 'no content display'
          return
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

  loadContent: (name, section, slug, route, query, passOptions) ->

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
                return onError err if err? or not model
                models[i] = model
                if models.length is jName.slugs.length
                  onSuccess models
                else onError()
          else onError()

  clear: (route, replaceState = yes) ->

    unless route
      {entryPoint} = KD.config
      route = if KD.isLoggedIn() and KD.isGroup() and not KD.isKoding()
      then "/#{KD.config.entryPoint?.slug}"
      else '/'

    super route, replaceState
