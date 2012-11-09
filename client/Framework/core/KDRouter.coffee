class KDRouter extends KDObject

  listenerKey = 'ಠ_ಠ'

  constructor:(routes)->
    @tree   = {} # this is the tree for quick lookups
    @routes = {} # this is the flat namespace containing all routes
    @currentPath = location.pathname 
    @addRoutes routes
    # this handles the case that the url is an "old-style" hash fragment hack.
    if location.hash.length
      @handleRoute location.hash.substr(1), shouldPushState: yes
    @startListening()

  onpopstate:(event)=> # fat-arrow binding makes this handler easier to remove.
    @currentPath = location.pathname
    @handleRoute location.pathname,
      shouldPushState   : no
      state             : KD.remote.revive(event.state)

  startListening:->
    return no  if @isListening # make this action idempotent
    @isListening = yes
    # we need to add a listener to the window's popstate event:
    window.addEventListener 'popstate', @onpopstate
    return yes

  stopListening:->
    return no  unless @isListening # make this action idempotent
    @isListening = no
    window.removeEventListener 'popstate', @onpopstate
    return yes

  getTitle:(path)-> path
  
  handleNotFound:(route)-> log "The route #{route} was not found!"

  addRoute:(route, listener)->
    @routes[route] = listener
    node = @tree
    route = route.split '/'
    route.shift() # first edge is garbage like '' or '#!'
    for edge, i in route
      len = edge.length-1
      if '?' is edge.substr len # then this is an "optional edge".
        # recursively alias this route without this optional edge:
        routeWithoutThisEdge = "/#{
          route.slice(0, i).concat(route.slice i + 1).join '/'
          # route.filter (_, k)-> k isnt i
        }"
        @addRoute routeWithoutThisEdge, listener
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

  handleRoute:(frag, options={})->
    {shouldPushState, state} = options
    shouldPushState ?= yes
    node = @tree
    params = {}
    isRooted = '/' is frag[0]

    frag = frag.split '/'
    frag.shift() # first edge is garbage like '' or '#!'

    path = frag.join '/'

    if shouldPushState
      method = if options.replaceState then 'replaceState' else 'pushState'
      history[method] state, @getTitle(path), "/#{path}"

    for edge in frag
      if node[edge]
        node = node[edge]
      else
        param = node[':']
        if param?
          params[param.name] = edge
          node = param
        else @handleNotFound frag.join '/'

    listeners = node[listenerKey]
    if listeners?.length
      listener.call @, params, state for listener in listeners
