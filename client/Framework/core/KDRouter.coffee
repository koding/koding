class KDRouter

  listenerKey = 'ಠ_ಠ'

  tree = {}

  getHashFragment =(url)-> url.substr url.indexOf '#'

  handleNotFound =(route)=> @handleNotFound? route

  changeRoute =(frag)->
    node = tree
    params = {}
    frag = frag.split('/')
    frag.shift() # first edge is garbage like '' or '#!'

    for edge in frag
      if node[edge]
        node = node[edge]
      else
        param = node[':']
        if param?
          params[param.name] = edge
          node = param
        else handleNotFound frag.join('/')

    listeners = node[listenerKey]
    if listeners?.length
      listener.call null, params for listener in listeners

  # window.addEventListener 'popstate', (event)->
  #   log event
  #   log location

  window.addEventListener 'hashchange', (event)->
    changeRoute getHashFragment(event.newURL)

  @init =-> changeRoute location.hash.substr 1 if location.hash.length

  @handleNotFound =-> log "The route #{route} was not found!"

  @handleRoute =(route)-> changeRoute route

  @addRoutes =(routes)->
    @addRoute route, listener for own route, listener of routes

  @addRoute =(route, listener)->
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
