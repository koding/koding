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

  setListeningTo:(obj)->
    @listeningTo.push obj

  registerSingleton:KD.registerSingleton

  getSingleton:KD.getSingleton

  getInstance:(instanceId)->
    KD.getAllKDInstances()[instanceId] ? null

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

  setOptions:(@options = {})->

  setOption:(option, value)-> @options[option] = value

  unsetOption:(option)-> delete @options[option] if @options[option]

  getOptions:-> @options
  getOption:(key)-> @options[key] or null

  changeId:(id)->
    KD.deleteInstance @
    @id = id
    KD.registerInstance @

  getId:->@id

  setDelegate:(@delegate)->

  getDelegate:->@delegate

  destroy:->

    @emit 'KDObjectWillBeDestroyed'
    KD.removeSubscriptions @
    for obj in @listeningTo
      obj.removeListener listener : @

    id = @id
    KD.deleteInstance id
