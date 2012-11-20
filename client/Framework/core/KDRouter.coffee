class KDRouter extends KDObject

  listenerKey = 'ಠ_ಠ'

  createObjectRef =(obj)->
    return unless obj?.bongo_? and obj?.getId?
    constructorName   : obj.bongo_?.constructorName
    id                : obj.getId()

  revive =(objRef, callback)->
    unless objRef?.constructorName? and objRef.id? then callback null
    else KD.remote.cacheable objRef.constructorName, objRef.id, callback

  constructor:(routes)->
    super()
    @tree   = {} # this is the tree for quick lookups
    @routes = {} # this is the flat namespace containing all routes
    @addRoutes routes
    # this handles the case that the url is an "old-style" hash fragment hack.
    if location.hash.length
      hashFragment = location.hash.substr 1
      @utils.defer => @handleRoute hashFragment, shouldPushState: yes
    @startListening()

  onpopstate:(event)=> # fat-arrow binding makes this handler easier to remove.
    revive event.state, (err, state)=>
      if err?
        new KDNotificationView title: 'An unknown error has occurred.'
      else
        @handleRoute location.pathname,
          shouldPushState   : no
          state             : state

  clear:(replaceState=yes)-> @handleRoute '/', {replaceState}

  startListening:->
    return no  if @isListening # make this action idempotent
    @isListening = yes
    # we need to add a listener to the window's popstate event:
    window.addEventListener 'popstate', @onpopstate
    return yes

  stopListening:->
    return no  unless @isListening # make this action idempotent
    @isListening = no
    # we need to remove the listener from the window's popstate event:
    window.removeEventListener 'popstate', @onpopstate
    return yes

  @handleNotFound =(route)-> log "The route #{route} was not found!"

  getTitle:(path)-> path
  
  handleNotFound:(route)->
    console.trace()
    log "The route #{route} was not found!"

  routeWithoutEdgeAtIndex =(route, i)->
    "/#{route.slice(0, i).concat(route.slice i + 1).join '/'}"

  addRoute:(route, listener)->
    @routes[route] = listener
    node = @tree
    route = route.split '/'
    route.shift() # first edge is garbage like '' or '#!'
    for edge, i in route
      len = edge.length-1
      if '?' is edge.substr len # then this is an "optional edge".
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
    node[listenerKey].push listener

  addRoutes:(routes)->
    @addRoute route, listener  for own route, listener of routes

  handleQuery:(query)->
    query = @utils.stringifyQuery query  unless 'string' is typeof query
    return  unless query.length
    nextRoute = "/#{@currentPath}?#{query}"
    @handleRoute nextRoute

  handleRoute:(frag, options={})->
    [frag, query...] = (frag ? @getDefaultRoute?() ? '/').split '?'
    query = @utils.parseQuery query.join '&'
    {shouldPushState, replaceState, state} = options
    objRef = createObjectRef state
    shouldPushState ?= yes
    node = @tree
    params = {}
    isRooted = '/' is frag[0]

    frag = frag.split '/'
    frag.shift() # first edge is garbage like '' or '#!'

    path = frag.join '/'

    qs = @utils.stringifyQuery query
    path += "?#{qs}"  if qs.length

    if shouldPushState and not replaceState and path is @currentPath
      @emit 'AlreadyHere', path
      return

    @currentPath = path

    if shouldPushState
      method = if replaceState then 'replaceState' else 'pushState'
      history[method] objRef, @getTitle(path), "/#{path}"

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
    
    listeners = node[listenerKey]
    if listeners?.length
      listener.call @, routeInfo, state, path  for listener in listeners
