class Kite extends KDObject

  [ NOTREADY, READY ] = [ 0, 1 ]

  { Scrubber, Store } = Bongo.dnodeProtocol

  constructor: (options, data) ->
    super

    { @kiteName, @correlationName, @kiteKey } = options

    @initChannel()

    @localStore   = new Store
    @remoteStore  = new Store

    @readyState = NOTREADY

  createId: Bongo.createId

  initChannel: ->
    @entropy        = @createId 128
    @qualifiedName  = "kite-#{@kiteName}"

    @channelName  = @getChannelName()

    @channel = KD.remote.mq.subscribe @channelName
    @channel.setAuthenticationInfo
      serviceType       : 'kite'
      name              : @qualifiedName
      correlationName   : @correlationName
      clientId          : KD.remote.getSessionToken()

    @channel.cycleChannel               = @bound 'cycleChannel'
    @channel.ping                       = @bound 'pingChannel'
    @channel.setStartPinging            = @bound 'setStartPinging'
    @channel.setStopPinging             = @bound 'setStopPinging'

    @channel.on 'message'               , @bound 'handleChannelMessage'
    @channel.on 'message'               , @bound 'handleMessageArrived'
    @channel.on 'publish'               , @bound 'handleChannelPublish'
    @channel.on 'possibleUnresponsive'  , @bound 'handleSuspectChannel'
    @channel.on 'unresponsive'          , @bound 'handleUnresponsiveChannel'

  handleBrokerSubscribed:->

  cycleChannel: ->
    @setStopPinging()
    @channel.off()

    @initChannel()
    @emit 'destroy'

  pingChannel: (callback) ->
    return if @stopPinging
    @channel.publish JSON.stringify
      method      : 'ping'
      arguments   : []
      callbacks   : {}
    @channel.once 'pong', callback  if callback

  setStartPinging: -> @stopPinging = yes

  setStopPinging: -> @stopPinging = no

  handleMessageArrived: ->
    clearTimeout @unresponsiveTimeoutId

    @unresponded = 0

    @pingTimeoutId = setTimeout =>
      @pingChannel()
    , 10000

  handleChannelMessage: (args) ->

    {method} = args

    callback = switch method
      when 'ready'            then @bound 'handleReady'
      when 'error'            then @bound 'handleError'
      when 'ping'             then @bound 'handlePing'
      when 'pong'             then @bound 'handlePong'
      when 'cycleChannel'     then @bound 'cycleChannel'
      else (@localStore.get method) ? ->

    callback.apply this, @unscrub args

  handleChannelPublish: ->
    clearTimeout @pingTimeoutId           if @pingTimeoutId?
    clearTimeout @unresponsiveTimeoutId   if @unresponsiveTimeoutId?

    delete @pingTimeoutId
    delete @unresponsiveTimeoutId

    @unresponsiveTimeoutId = setTimeout =>
      @emit "possibleUnresponsive"
    , 5000

  handleSuspectChannel: ->
    @unresponded ||= 0
    log 'possibleUnresponsive', @channel.name, @unresponded
    @unresponded++
    if @unresponded > 1 then @emit 'unresponsive' else @ping()

  handleUnresponsiveChannel: ->
    log 'unresponsive', @channel.name
    @cycleChannel()

  ready:(callback)->
    return KD.utils.defer callback  if @readyState is READY
    @once 'ready', callback

  handleReady: (resourceName)->
    @readyState = READY
    @channel.exchange = resourceName
    @emit 'ready'

  handleError: (err) -> console.error err

  handlePing: ->
    @channel.publish JSON.stringify
      method      : 'pong'
      arguments   : []
      callbacks   : {}

  handlePong: ->
    @channel.emit 'pong'
    @lastPong = Date.now()

  handleRequest: (method, args) ->
    @scrub method, args, (scrubbed) =>
      messageString = JSON.stringify(scrubbed)
      @ready => @channel.publish messageString

  scrub: (method, args, callback) ->
    scrubber = new Scrubber @localStore
    scrubber.scrub args, =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method or= method
      callback scrubbed

  unscrub: (args) ->
    scrubber = new Scrubber @localStore
    return scrubber.unscrub args, (callbackId) =>
      unless @remoteStore.has callbackId
        @remoteStore.add callbackId, (rest...) =>
          @handleRequest callbackId, rest
      @remoteStore.get callbackId

  getChannelName: ->
    delegate  = KD.whoami()
    nickname  = delegate?.profile.nickname ?
                if delegate.guestId then "guest#{delegate.guestId}" ?
                'unknown'
    channelName = "#{@entropy}.#{nickname}.#{@qualifiedName}"
    return channelName

  tell:(options, callback) ->
    @handleRequest options.method, [options, callback]

