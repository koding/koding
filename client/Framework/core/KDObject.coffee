class KDObject extends KDEventEmitter

  READY = 1

  utils: __utils

  constructor:(options = {}, data)->
    @id or= options.id or __utils.getUniqueId()
    @setOptions options
    @setData data  if data
    @setDelegate options.delegate if options.delegate
    @registerKDObjectInstance()
    @subscriptionsByEvent = {}
    @subscriptionCountByListenerId = {}
    @listeningTo = []
    super
    @once 'ready', => @readyState = READY

  if KD.MODE is 'development'
    interfere:(o)-> o
    o:(o)-> @interfere o
  else
    o:(o)->o

  bound: Bongo.bound

  ready:(listener)->
    if @readyState > 0 then listener()
    else @once 'ready', listener

  inheritanceChain:(options)->
    #need to detect () to know whether to call as function or get value as parameter
    methodArray = options.method.split "."
    options.callback
    proto = @__proto__
    chain = @
    chain = chain[method] for method in methodArray
    while proto = proto.__proto__
      newChain = proto
      newChain = newChain[method] for method in methodArray
      chain = options.callback chain:chain,newLink:newChain
    chain

  chainNames:(options)->
    options.chain
    options.newLink
    "#{options.chain}.#{options.newLink}"

  listenToOnce:(KDEventTypes,callback,obj)->
    options = @_listenToAdapter KDEventTypes, callback, obj
    if (obj = options.obj)?
      options.listener = @
      obj.registerListenOncer options
    else
      return error "you should pass at least a callback for KDObject.listenToOnce() method to work." unless callback?
      onceCallback = (source, data, {subscription})->
        options.callback arguments
        KD.getAllSubscriptions().splice (KD.getAllSubscriptions().indexOf subscription), 1
      options.callback = onceCallback
      @_listenTo options

  listenTo:(KDEventTypes,callback,obj)->
    options = @_listenToAdapter KDEventTypes, callback, obj
    @_listenTo options

  _listenToAdapter:(KDEventTypes, callback, obj)->

    # temporary migration code
    #listenTo:({KDEventTypes,listenedToInstance,callback,callbacks})->
    if KDEventTypes.KDEventTypes? # for backwards compatibility
      options = KDEventTypes

      if options.KDEventTypes
        options.KDEventTypes = [options.KDEventTypes] unless $.isArray options.KDEventTypes

      KDEventTypes = for event in options.KDEventTypes
        unless event.className? or event.eventType? #default property is eventType
          event =
            eventType : event
        # FIXME: if no className, "eventType" should become "eventType." to distinguish between e.g. "Scroll" and "KDScrollViewAppended"
        (if event.className is "KDData" then "Data" else (event.className or "")) + (event.eventType?.capitalize() or (".#{event.property}" if event.property?) or "")
      obj = options.listenedToInstance
      callback = options.callback
      callbacks = options.callbacks

    # /temporary migration code
    {KDEventTypes, callback, callbacks, obj}

  _listenTo:({KDEventTypes, callback, callbacks, obj})->
    return error "you should pass at least a callback for KDObject.listenTo() method to work. (#{KDEventTypes})" unless callback? or callbacks?

    unless obj?
      if KDEventTypes
        KDEventTypes = [KDEventTypes] unless $.isArray KDEventTypes
        for KDEventType in KDEventTypes
          KD.subscribe
            subscribingInstance : @
            KDEventType           : KDEventType.capitalize()
            callback            : callback
      else
        KD.subscribe
          subscribingInstance : @
          KDEventType           : null
          callback            : callback
    else
      KDEventTypes = obj.registerListener {KDEventTypes, callback, callbacks, listener:@} #return value is always an array, so save checking in further methods

  registerListener:({KDEventTypes, callback, listener})->
    # @listeners = [] unless @listeners
    KDEventTypes = KDEventTypes
    if KDEventTypes
      KDEventTypes = [KDEventTypes] unless $.isArray KDEventTypes
      for KDEventType in KDEventTypes
        KDEventType = KDEventType.capitalize()
        (@subscriptionsByEvent[KDEventType] or= []).push {KDEventType, listener, callback}
        count = ((@subscriptionCountByListenerId[listener.id] or= {})[KDEventType] or= 0)
        count++
    else
      (@subscriptionsByEvent.KDAnyEvent or= []).push {KDEventType : 'KDAnyEvent', listener, callback}
      count = ((@subscriptionCountByListenerId[listener.id] or= {}).KDAnyEvent or= 0)
      count++
    listener?.setListeningTo @

  registerListenOncer:({KDEventTypes, callback, listener})->
    self = @
    onceCallback = (source, data, {subscription})->
      callback.apply listener, arguments
      (subscriptionList = self.subscriptionsByEvent[subscription.KDEventType]).splice (subscriptionList.indexOf subscription), 1
      self.subscriptionCountByListenerId[listener.id][subscription.KDEventType]--
      # @listeners.splice (@listeners.indexOf subscription), 1
    @registerListener {KDEventTypes, callback : onceCallback, listener}

  setListeningTo:(obj)->
    @listeningTo.push obj

  registerSingleton:KD.registerSingleton

  getSingleton:KD.getSingleton

  getInstance:(instanceId)->
    KD.getAllKDInstances()[instanceId] ? null


  propagateEvent: ({KDEventType, globalEvent},data)->
    globalEvent or= no
    KDEventType = KDEventType.capitalize()
    if KDEventType of @subscriptionsByEvent
      for subscription in @subscriptionsByEvent[KDEventType]
        subscription.callback.call subscription.listener, @, data, {subscription}
    if 'KDAnyEvent' of @subscriptionsByEvent
      for subscription in @subscriptionsByEvent.KDAnyEvent
        subscription.callback.call subscription.listener, @, data, {subscription}
    KD.propagateEvent KDEventType, @, data if globalEvent

  removeListener:( {listener} )->
    for eventType, count of @subscriptionCountByListenerId[listener]
      subscriptionList = @subscriptionsByEvent[eventType]
      _i = 0; subscriptionListCopy = subscriptionList.slice 0; _len = subscriptionListCopy.length
      while count > 0 and _i < _len
        if subscriptionListCopy[_i].listener is listener
          subscriptionList.splice _i, 1
          count--
        _i++
      subscriptionCountByListenerId[listener][eventType] = 0

  requireLogin:KD.requireLogin

  registerKDObjectInstance: -> KD.registerInstance @

  setData:(data)->
    return warn "setData called with null or undefined!" unless data?
    @data = data
    # fix
    # this unfortunately doesn't work
    # because we change the data here.
    # in a view constructor we do data.on "update"
    # but here that data is reset/changed and listener becomes obsolete
    # bc new data isn't being listened
    data.emit? 'update'

  getData:-> @data

  setOptions:(options)->
    @options = options ? {}

  setOption:(option, value)->
    @options[option] = value

  unsetOption:(option)->
    delete @options[option] if @options[option]

  getOptions:->
    @options

  changeId:(id)->
    KD.deleteInstance @
    @id = id
    KD.registerInstance @

  getId:()->@id

  setDelegate:(anInstance)-> @delegate = anInstance

  getDelegate:->@delegate

  destroy:()->

    @emit 'KDObjectWillBeDestroyed'
    KD.removeSubscriptions @
    for obj in @listeningTo
      obj.removeListener listener : @

    id = @id
    KD.deleteInstance id
