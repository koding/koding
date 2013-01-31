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
    registry[event] ?= []
    # register the listeners callback.
    registry[event].push callback

  _off = (registry, eventName, callback)->
    if event is "*"
      registry = {}
    # reset the listener container so no event
    # will be propagated to previously registered
    # listener callbacks.
    else if callback and registry[event]
      cbIndex = registry[event].indexOf callback
      registry[event].splice 1, cbIndex if cbIndex >= 0
    else
      registry[event] = []


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
    [event, args...] = [].slice.call arguments
    # create listener container if it doesn't exist
    _e[event] ?= []
    # call every listener inside the container with the arguments (args)
    listener.apply null,args for listener in _e[event] if _e[event]?

  @on   :(event,callback)->  _on _e, event, callback
  @off  :(event, callback)-> _off _e, event, callback

  constructor:->
    @KDEventEmitterEvents  = {}
    @_e = @KDEventEmitterEvents[@constructor.name] = {}

  emit:(event, args...)->
    @_e[event] ?= []

    listenerStack = []

    for own eventName of @_e
      continue if eventName is event
      parser = getEventParser eventName
      if parser.test event
        listenerStack = listenerStack.concat @_e[eventName].slice(0)

    listenerStack = listenerStack.concat @_e[event].slice(0)

    listenerStack.forEach (listener)=>
      listener.apply @, args

  on  :(event, callback) -> _on  @_e, event, callback
  off :(event, callback) -> _off @_e, event, callback
  unsubscribe:(event, callback) -> _off @_e, event, callback

  once:(event, callback) ->
    _callback = () =>
      args = [].slice.call arguments
      @unsubscribe event, _callback
      callback.apply @, args

    @on event, _callback

