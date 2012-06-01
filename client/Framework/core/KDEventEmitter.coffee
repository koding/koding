#
# KDEventEmitter
# author : devrim - 12/27/2011
#

class KDEventEmitter
  @KDEventEmitterEvents = {}
    
  _e = @KDEventEmitterEvents[@name] = {}                                  # listeners will be put inside @KDEventEmitterEvents[className]

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
    
    [event, args...] = [].slice.call arguments                            # slice the arguments, 1st argument is the event name, rest is args supplied with emit.
    _e[event] ?= []                                                       # create listener container if it doesn't exist    
    listener.apply null,args for listener in _e[event] if _e[event]?      # call every listener inside the container with the arguments (args)
    
  @on   : (event,callback)->
    
    _e[event] ?= []                                                       # on can be defined before any emit, so create the event container, if it doesn't exist.
    _e[event].push callback                                               # register the listeners callback.
    
  @off  : (event)-> 
    if event is "*" then _e = {} else _e[event] = []                      # reset the listener container so no event will be propagated to previously registered listener callbacks.

    
  constructor:()->
    @KDEventEmitterEvents  = {}
    @_e = @KDEventEmitterEvents[@constructor.name] = {}
    
  # nextTick: (fn) ->
  #   setTimeout fn, 0
     
  emit : (event, args...)->

    @_e[event] ?= []

    listenerStack = []
    
    for own eventName of @_e
      continue if eventName is event
      parser = getEventParser eventName
      if parser.test event
        listenerStack = listenerStack.concat @_e[eventName].slice(0)
        
    listenerStack = listenerStack.concat @_e[event].slice(0)
    
    listenerStack.forEach (listener)=>
      listener.apply null,args 
      # @nextTick ->
      #   listener.apply null,args 

  on : (event,callback) ->
    @_e[event] ?= []
    @_e[event].push callback

  off : (event) -> 
    if event is "*" then @_e = {} else @_e[event] = []
    
  unsubscribe: (event, callback) ->
    if @_e[event]
      index = @_e[event].indexOf callback
      if index > -1
        # log "removed event:#{event} from subscribe list"
        @_e[event].splice index, 1
    
  once: (event, callback) ->
    _callback = () =>
      args = [].slice.call arguments
      @unsubscribe event, _callback
      callback.apply null, args
    
    @on event, _callback
      
