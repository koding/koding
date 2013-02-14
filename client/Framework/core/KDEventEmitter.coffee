# KDEventEmitter
# author : devrim - 12/27/2011
# refactored : sinan - 05/2012
# refactored : sinan - 01/2013

class KDEventEmitter
  @KDEventEmitterEvents = {}

  # listeners will be put inside @KDEventEmitterEvents[className]
  _e = @KDEventEmitterEvents[@name] = {}

  _on = (registry, eventName, callback)->
    # on can be defined before any emit, so create
    # the event registry, if it doesn't exist.
    registry[eventName] ?= []
    # register the listeners callback.
    registry[eventName].push callback

  _off = (registry, eventName, callback)->
    if eventName is "*"
      registry = {}
    # reset the listener container so no event
    # will be propagated to previously registered
    # listener callbacks.
    else if callback and registry[eventName]
      cbIndex = registry[eventName].indexOf callback
      registry[eventName].splice cbIndex, 1 if cbIndex >= 0
    else
      registry[eventName] = []


  getEventParser = (event)->

    ///^
    #{event.replace(/\./g,'\\.').replace(/\*/g, '((?:\\w+\\.?)*)')}
    $///

  #
  # STATIC METHODS
  #####################
  # user is able to do ClassName.on .emit
  #

  @emit : ->
    # slice the arguments, 1st argument is the event name,
    # rest is args supplied with emit.
    [eventName, args...] = [].slice.call arguments
    # create listener container if it doesn't exist
    _e[eventName] ?= []
    # call every listener inside the container with the arguments (args)
    listener.apply null,args for listener in _e[eventName] if _e[eventName]?

  @on   :(eventName, callback)-> _on _e, eventName, callback
  @off  :(eventName, callback)-> _off _e, eventName, callback

  constructor:->
    @KDEventEmitterEvents  = {}
    @_e = @KDEventEmitterEvents[@constructor.name] = {}

  emit:(eventName, args...)->
    @_e[eventName] ?= []

    listenerStack = []

    for own eventToBeFired of @_e
      continue if eventToBeFired is eventName
      parser = getEventParser eventToBeFired
      if parser.test eventName
        listenerStack = listenerStack.concat @_e[eventToBeFired].slice(0)

    listenerStack = listenerStack.concat @_e[eventName].slice(0)

    listenerStack.forEach (listener)=>
      listener.apply @, args

  on  :(eventName, callback) -> _on  @_e, eventName, callback
  off :(eventName, callback) -> _off @_e, eventName, callback
  unsubscribe:(eventName, callback) -> _off @_e, eventName, callback

  once:(eventName, callback) ->
    _callback = =>
      args = [].slice.call arguments
      @off eventName, _callback
      callback.apply @, args

    @on eventName, _callback

