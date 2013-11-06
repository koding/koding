class NewKite extends KDObject

  { Scrubber, Store } = Bongo.dnodeProtocol

  [NOTREADY, READY, CLOSED] = [0,1,3]

  constructor: (options)->

    super options

    { @addr, @name, @token, @correlationName, @publicIP, @port } = options
    @localStore   = new Store
    @remoteStore  = new Store
    @tokenStore = {}
    @autoReconnect = true
    @readyState = NOTREADY

    # addr is shortcut for IP and port.
    # It is not present in Kite structure sent from Kontrol.
    @addr or= ""
    if options.publicIP and options.port
      @addr = options.publicIP + ":" + options.port

    @token or= ""
    @initBackoff options  if @autoReconnect
    @connect()

  connect:->
    if @addr
    then @connectDirectly()
    else @getKiteAddr(true)

  bound: Bongo.bound

  connectDirectly:->
    log "trying to connect to #{@addr}"
    @ws = new WebSocket "ws://#{@addr}/sock"
    @ws.onopen    = @bound 'onOpen'
    @ws.onclose   = @bound 'onClose'
    @ws.onmessage = @bound 'onMessage'
    @ws.onerror   = @bound 'onError'

  getKiteAddr : (connect=no)->
    KD.getSingleton("kontrol").getKites @name, (err, kites) =>
      if err
        log "kontrol request error", err
        # Make a request again if we could not get the addres, use backoff for that
        KD.utils.defer => @setBackoffTimeout =>
          @getKiteAddr true
      else
        # kite and token comes in seperate objects. See protocol.go.
        first = kites[0]
        kite = first.kite
        @token = first.token
        @addr = kite.publicIP + ":" + kite.port

        # this should be optional
        @connectDirectly() if connect

  disconnect:(reconnect=true)->
    @autoReconnect = !!reconnect  if reconnect?
    @ws.close()

  onOpen:->
    log "I'm connected to #{@name} at #{@addr}. Yayyy!"
    @clearBackoffTimeout()
    @readyState = READY
    @emit 'KiteConnected', @name
    @emit 'ready'

  onClose: (evt) ->
    # log "#{@name}: disconnected, trying to reconnect"
    @readyState = CLOSED
    @emit 'KiteDisconnected', @name
    # enable below to autoReconnect when the socket has been closed
    # if @autoReconnect
    #   KD.utils.defer => @setBackoffTimeout @bound "connect"

  onMessage: (evt) ->
    try
      args = JSON.parse evt.data
    catch e
      log "json parse error: ", e, evt.data

    if args and not e
      err = args.arguments[0]
      {method} = args
      callback = switch method
        when 'ping'             then @bound 'handlePing'
        else (@localStore.get method) ? ->

      callback.apply this, @unscrub args

  onError: (evt) ->
    # log "#{@name}: error #{evt.data}"

  handlePing: ->
    @send JSON.stringify
      method      : 'pong'
      arguments   : []
      callbacks   : {}

  initBackoff:(options)->
    backoff = options.backoff ? {}
    totalReconnectAttempts = 0
    initalDelayMs = backoff.initialDelayMs ? 700
    multiplyFactor = backoff.multiplyFactor ? 1.4
    maxDelayMs = backoff.maxDelayMs ? 1000 * 15 # 15 seconds
    maxReconnectAttempts = backoff.maxReconnectAttempts ? 50

    @clearBackoffTimeout =->
      totalReconnectAttempts = 0

    @setBackoffTimeout = (fn)=>
      if totalReconnectAttempts < maxReconnectAttempts
        timeout = Math.min initalDelayMs * Math.pow(
          multiplyFactor, totalReconnectAttempts
        ), maxDelayMs
        setTimeout fn, timeout
        totalReconnectAttempts++
      else
        @emit "connectionFailed"

  ready: (callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  unscrub: (args) ->
    scrubber = new Scrubber @localStore
    return scrubber.unscrub args, (callbackId) =>
      unless @remoteStore.has callbackId
        @remoteStore.add callbackId, (rest...) =>
          @handleRequest callbackId, rest
      @remoteStore.get callbackId

  handleRequest: (method, args) ->
    @scrub method, args, (scrubbed) =>
      @ready => @send scrubbed

  scrub: (method, args, callback) ->
    scrubber = new Scrubber @localStore
    scrubber.scrub args, =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method or= method
      callback scrubbed

  tell:(options, callback) ->
    @ready =>
      # token is needed to initiate a valid session
      options.token = @token
      options.username  = "#{KD.nick()}"
      # options.correlationName = "vm-100.devrim.koding.kd.io"
      @handleRequest options.method, [options, callback]

  send: (data) ->
    try
      if @readyState is READY
        @ws.send JSON.stringify data
      else
        # log "slow down ... I'm still trying to reconnect!"
    catch e
      @disconnect()

