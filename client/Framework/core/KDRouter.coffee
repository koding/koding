class KDRouter

  listenerKey = 'ಠ_ಠ'

  tree = {}

  currentPath = location.pathname

  getHashFragment =(url)-> url.substr 1 + url.indexOf '#'

  handleNotFound =(route)=> @handleNotFound? route

  changeRoute =(frag, options={})->
    {shouldPushState} = options
    node = tree
    params = {}
    isRooted = '/' is frag[0]

    frag = frag.split '/'
    frag.shift() # first edge is garbage like '' or '#!'

    path = frag.join '/'
    
    if shouldPushState
      history[if options.replaceState then 'replaceState' else 'pushState'](
        {}, KDRouter.getTitle(path), "/#{path}"
      )

    for edge in frag
      if node[edge]
        node = node[edge]
      else
        param = node[':']
        if param?
          params[param.name] = edge
          node = param
        else handleNotFound frag.join '/'

    listeners = node[listenerKey]
    if listeners?.length
      listener.call @, params for listener in listeners

  window.addEventListener 'popstate', (event)=>
    currentPath = location.pathname
    changeRoute.call @, location.pathname, shouldPushState: no

  @routes = {}

  @getTitle =(path)-> path

  @init =->
    if location.hash.length
      changeRoute.call @, location.hash.substr(1), shouldPushState: yes
  
  @handleNotFound =(route)-> log "The route #{route} was not found!"

  @handleRoute =(route, options={})->
    options.shouldPushState ?= yes
    changeRoute.call @, route, options

  @addRoutes =(routes)->
    @addRoute route, listener for own route, listener of routes

  @addRoute =(route, listener)->
    @routes[route] = listener
    node = tree
    route = route.split('/')
    route.shift() # first edge is garbage like '' or '#!'
    for edge in route
      if /^:/.test edge
        node[':'] or= name: edge.substr 1
        node = node[':']
      else
        node[edge] or= {}
        node = node[edge]
    node[listenerKey] or= []
    node[listenerKey].push listener
