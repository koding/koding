# KDEventEmitter
# author     : devrim - 12/27/2011
# refactored : sinan - 05/2012
# refactored : sinan - 01/2013
# improved   : sinan - 02/2013

class KDEventEmitter

  # listeners will be put inside @KDEventEmitterEvents[className]
  _e = {}

  _registerEvent = (registry, eventName, callback)->
    # on can be defined before any emit, so create
    # the event registry, if it doesn't exist.
    registry[eventName] ?= []
    # register the listeners callback.
    registry[eventName].push callback

  _unregisterEvent = (registry, eventName, callback)->
    if eventName is "*"
      registry = {}
    # reset the listener container so no event3
    # will be propagated to previously registered
    # listener callbacks.
    else if callback and registry[eventName]
      cbIndex = registry[eventName].indexOf callback
      registry[eventName].splice cbIndex, 1 if cbIndex >= 0
    else
      registry[eventName] = []

  _on = (registry, eventName, callback)->
    throw new Error 'Try passing a listener, genius!'  unless callback?
    if Array.isArray eventName
      _registerEvent registry, name, callback for name in eventName
    else
      _registerEvent registry, eventName, callback


  _off = (registry, eventName, callback)->
    if Array.isArray eventName
      _unregisterEvent registry, name, callback for name in eventName
    else
      _unregisterEvent registry, eventName, callback


  getEventParser = (event)->

    ///^
    #{event.replace(/\./g,'\\.').replace(/\*/g, '((?:\\w+\\.?)*)')}
    $///

  #
  # STATIC METHODS
  #####################
  # user is able to do ClassName.on .emit
  #

  @emit: ->
    # slice the arguments, 1st argument is the event name,
    # rest is args supplied with emit.
    [eventName, args...] = [].slice.call arguments
    # create listener container if it doesn't exist
    _e[eventName] ?= []
    # call every listener inside the container with the arguments (args)
    listener.apply null,args for listener in _e[eventName] if _e[eventName]?
    return this

  @on: (eventName, callback) ->
    _on _e, eventName, callback
    return this

  @off: (eventName, callback) ->
    _off _e, eventName, callback
    return this

  constructor:->
    @_e = {}

  emit:(eventName, args...)->
    @_e[eventName] ?= []

    listenerStack = []

    # for own eventToBeFired of @_e
    #   continue if eventToBeFired is eventName
    #   parser = getEventParser eventToBeFired
    #   if parser.test eventName
    #     listenerStack = listenerStack.concat @_e[eventToBeFired].slice(0)

    listenerStack = listenerStack.concat @_e[eventName].slice(0)

    listenerStack.forEach (listener)=>
      listener.apply @, args

  on  :(eventName, callback) -> _on  @_e, eventName, callback
  off :(eventName, callback) -> _off @_e, eventName, callback

  once:(eventName, callback) ->
    _callback = =>
      args = [].slice.call arguments
      @off eventName, _callback
      callback.apply @, args

    @on eventName, _callback

