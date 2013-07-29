class KDRouter extends KDObject

  {history} = window

  listenerKey = 'ಠ_ಠ'

  createObjectRef =(obj)->
    return unless obj?.bongo_? and obj.getId?
    constructorName   : obj.bongo_?.constructorName
    id                : obj.getId()

  revive =(objRef, callback)->
    unless objRef?.constructorName? and objRef.id? then callback null
    else KD.remote.cacheable objRef.constructorName, objRef.id, callback

  constructor:(routes)->
    super()
    @tree          = {} # this is the tree for quick lookups
    @routes        = {} # this is the flat namespace containing all routes
    @visitedRoutes = []
    @addRoutes routes  if routes

  listen:->
    # this handles the case that the url is an "old-style" hash fragment hack.
    if location.hash.length
      hashFragment = location.hash.substr 1
      @userRoute = hashFragment
      @utils.defer => @handleRoute hashFragment,
        shouldPushState   : yes
        replaceState      : yes
    @startListening()

  popState:(event)->
    revive event.state, (err, state)=>
      if err?
        new KDNotificationView title: 'An unknown error has occurred.'
      else
        @handleRoute "#{location.pathname}#{location.search}",
          shouldPushState   : no
          state             : state

  clear:(route = '/', replaceState = yes)->
    console.log {arguments}
    delete @userRoute # TODO: i hope deleting the userRoute here doesn't break anything... C.T.
    @handleRoute route, {replaceState}

  back:-> if @visitedRoutes.length <= 1 then @clear() else history.back()

  startListening:->
    return no  if @isListening # make this action idempotent
    @isListening = yes
    # we need to add a listener to the window's popstate event:
    window.addEventListener 'popstate', @bound "popState"
    return yes

  stopListening:->
    return no  unless @isListening # make this action idempotent
    @isListening = no
    # we need to remove the listener from the window's popstate event:
    window.removeEventListener 'popstate', @bound "popState"
    return yes

  @handleNotFound =(route)->
    console.trace()
    log "The route #{route} was not found!"

  getCurrentPath:-> @currentPath

  handleNotFound:(route)->
    delete @userRoute
    @clear()
    if location.hostname is "koding.com"
      log "The route #{route} was not found!"
      new KDNotificationView title: "404 Not found! #{route}"

  routeWithoutEdgeAtIndex =(route, i)->
    "/#{route.slice(0, i).concat(route.slice i + 1).join '/'}"

  addRoute:(route, listener)->

    # log "route added ---->", route

    @routes[route] = listener
    node = @tree
    route = route.split '/'
    route.shift() # first edge is garbage like '' or '#!'
    for edge, i in route
      len = edge.length - 1
      if '?' is edge.charAt len # then this is an "optional edge".
        # recursively alias this route without this optional edge:
        @addRoute routeWithoutEdgeAtIndex(route, i), listener
        edge = edge.substr 0, len # get rid of the "?" from the route
      if /^:/.test edge
        node[':'] or= name: edge.substr 1
        node = node[':']
      else
        node[edge] or= {}
        node = node[edge]
    node[listenerKey] or= []
    node[listenerKey].push listener  unless listener in node[listenerKey]

  addRoutes:(routes)->
    @addRoute route, listener  for own route, listener of routes

  handleRoute:(userRoute, options={})->

    userRoute = userRoute.slice 1  if (userRoute.indexOf '!') is 0
    @visitedRoutes.push userRoute

    [frag, query...] = (userRoute ? @getDefaultRoute?() ? '/').split '?'

    query = @utils.parseQuery query.join '&'

    {shouldPushState, replaceState, state, suppressListeners} = options
    shouldPushState ?= yes

    objRef = createObjectRef state

    node = @tree
    params = {}

    frag = frag.split '/'
    frag.shift() # first edge is garbage like '' or '#!'

    frag = frag.filter Boolean

    path = "/#{frag.join '/'}"

    qs = @utils.stringifyQuery query
    path += "?#{qs}"  if qs.length

    if not suppressListeners and shouldPushState and not replaceState and path is @currentPath
      @emit 'AlreadyHere', path
      return

    @currentPath = path

    if shouldPushState
      method = if replaceState then 'replaceState' else 'pushState'
      history[method] objRef, path, path

    for edge in frag
      if node[edge]
        node = node[edge]
      else
        param = node[':']
        if param?
          params[param.name] = edge
          node = param
        else @handleNotFound frag.join '/'

    routeInfo = {params, query}
    @emit 'Params', {params, query}

    unless suppressListeners
      listeners = node[listenerKey]
      if listeners?.length
        listener.call @, routeInfo, state, path  for listener in listeners

    return this

  handleQuery:(query)->
    query = @utils.stringifyQuery query  unless 'string' is typeof query
    return  unless query.length
    nextRoute = "#{@currentPath}?#{query}"
    @handleRoute nextRoute
