# KDEventEmitter
# author     : devrim - 12/27/2011
# refactored : sinan - 05/2012
# refactored : sinan - 01/2013
# improved   : sinan - 02/2013

# maxListenersError = (n) ->
#   return new Error \
#     '(node) warning: possible EventEmitter memory leak detected.' +
#     ' %d listeners added. Use emitter.setMaxListeners()' +
#     ' to increase limit.', n

class KDEventEmitter

  @registerWildcardEmitter = ->
    source = @Wildcard.prototype
    @::[prop] = val  for own prop, val of source

  @registerStaticEmitter = ->
    # static listeners will be put here
    @_e = {}

  _registerEvent = (registry, eventName, listener)->
    # on can be defined before any emit, so create
    # the event registry, if it doesn't exist.
    registry[eventName] ?= []
    # register the listeners listener.
    registry[eventName].push listener

  _unregisterEvent = (registry, eventName, listener)->
    if not eventName or eventName is "*"
      registry = {}
    # reset the listener container so no event3
    # will be propagated to previously registered
    # listener listeners.
    else if listener and registry[eventName]
      cbIndex = registry[eventName].indexOf listener
      registry[eventName].splice cbIndex, 1 if cbIndex >= 0
    else
      registry[eventName] = []

  _on = (registry, eventName, listener)->
    throw new Error 'Try passing an event, genius!'    unless eventName?
    throw new Error 'Try passing a listener, genius!'  unless listener?
    if Array.isArray eventName
      _registerEvent registry, name, listener for name in eventName
    else
      _registerEvent registry, eventName, listener


  _off = (registry, eventName, listener)->
    if Array.isArray eventName
      _unregisterEvent registry, name, listener for name in eventName
    else
      _unregisterEvent registry, eventName, listener


  # STATIC METHODS
  # to enable ClassName.on or ClassName.emit

  @emit: ->
    unless @_e?
      throw new Error 'Static events are not enabled for this constructor.'
    # slice the arguments, 1st argument is the event name,
    # rest is args supplied with emit.
    [eventName, args...] = arguments
    # create listener container if it doesn't exist
    listeners = @_e[eventName] ?= []
    # call every listener inside the container with the arguments (args)
    listener.apply null, args  for listener in listeners
    return this

  @on: (eventName, listener) ->
    unless 'function' is typeof listener
      throw new Error 'listener is not a function'

    unless @_e?
      throw new Error 'Static events are not enabled for this constructor.'

    @emit 'newListener', listener
    _on @_e, eventName, listener
    return this

  @off: (eventName, listener) ->
    @emit 'listenerRemoved', eventName, listener
    _off @_e, eventName, listener
    return this

  # INSTANCE METHODS
  # to enable anInstance.on or anInstance.emit (anInstance being new ClassName)

  constructor: (options = {})->
    { maxListeners } = options
    @_e             = {}
    @_maxListeners  = if maxListeners > 0 then maxListeners else 10

  emit:(eventName, args...)->
    @_e[eventName] ?= []

    listenerStack = []

    listenerStack = listenerStack.concat @_e[eventName].slice(0)
    listenerStack.forEach (listener)=> listener.apply @, args

  on  :(eventName, listener) ->
    unless 'function' is typeof listener
      throw new Error 'listener is not a function'

    @emit 'newListener', eventName, listener
    _on  @_e, eventName, listener
    return this

  off :(eventName, listener) ->
    @emit 'listenerRemoved', eventName, listener
    _off @_e, eventName, listener
    return this

  once:(eventName, listener) ->
    _listener = =>
      args = [].slice.call arguments
      @off eventName, _listener
      listener.apply @, args

    @on eventName, _listener
    return this

class KDEventEmitter.Wildcard extends KDEventEmitter

  wildcardKey = '*'
  listenerKey = '_listeners'

  constructor:(options = {})->
    super
    @_delim = options.delimiter or '.'

  setMaxListeners: (n) -> @_maxListeners = n

  getAllListeners = (node, edges, i = 0) ->

    listeners = []

    edge = edges[i]

    wild      = node[wildcardKey]
    straight  = node[listenerKey]
    nextNode  = node[edge]

    if straight? and i is edges.length
      listeners = listeners.concat straight

    if wild?
      listeners = listeners.concat getAllListeners wild, edges, i + 1

    if nextNode?
      listeners = listeners.concat getAllListeners nextNode, edges, i + 1

    return listeners

  removeAllListeners = (node, edges, id, i = 0) ->
    edge = edges[i]

    nextNode = node[edge]

    if nextNode?
      return removeAllListeners nextNode, edges, id, i + 1

    if id?
      straight = node[listenerKey]
      if straight?
        node[listenerKey] = (listener for listener in straight \
                             when listener isnt id)
    else
      node[listenerKey] = []

    return

  emit: (eventName, rest...) ->

    if @hasOwnProperty 'event' then oldEvent = @event

    @event = eventName

    listeners = getAllListeners @_e, eventName.split @_delim

    listener.apply this, rest  for listener in listeners

    if oldEvent?
      @event = oldEvent

    else
      delete @event

    return this

  off: (eventName, listener) ->
    removeAllListeners @_e, ((eventName ? '*').split @_delim), listener
    return this

  on: (eventName, listener) ->
    unless 'function' is typeof listener
      throw new Error 'listener is not a function'

    @emit 'newListener', eventName, listener

    edges = eventName.split '.'

    node = @_e

    for edge in edges
      node = node[edge] ?= {}

    listeners = node[listenerKey] ?= []

    listeners.push listener

    return this