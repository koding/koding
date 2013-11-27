# NewKite is a class for communicating with a remote Kite.
# It is analogous to RemoteKite class in go/koding/newkite/kite/remote.go file.
class NewKite extends KDObject

  [NOTREADY, READY, CLOSED] = [0,1,3]

  constructor: (kite, authentication, options={})->
    super options

    @kite = kite
    @authentication = authentication

    @readyState = NOTREADY
    @autoReconnect = true

    @initBackoff options  if @autoReconnect

    @handlers =
      log   : (options, cb)-> log options.withArgs
      alert : (options, cb)-> alert options.withArgs

    @proto = new Bongo.dnodeProtocol.Session null, @handlers
    @proto.on 'request', (req)=>
      log "proto request", {req}
      @ready =>
        @ws.send JSON.stringify req
    @proto.on 'fail', (err)=>
      log "proto fail", {err}
    @proto.on 'error', (err)=>
      log "proto error", {err}
    @proto.on 'remoteError', (err)=>
      log "proto remoteEerror", {err}

  connect: ->
    addr = @kite.publicIP + ":" + @kite.port
    log "Trying to connect to #{addr}"
    @ws = new WebSocket "ws://#{addr}/dnode"
    @ws.onopen    = @bound 'onOpen'
    @ws.onclose   = @bound 'onClose'
    @ws.onmessage = @bound 'onMessage'
    @ws.onerror   = @bound 'onError'

  disconnect: (reconnect=true)->
    @autoReconnect = !!reconnect  if reconnect?
    @ws.close()

  # Call a method on the connected Kite.
  tell: (method, args, cb) ->
    options =
      authentication : @authentication
      withArgs       : args

    # Normally the request is made with the following statement:
    #   @proto.request method, [options, cb]
    # However, we are making a single request/response call and
    # there is no point to hold the callback function because it
    # will never be called again. That's why we are deleting to
    # free the memory with the code below.
    scrubber = new Bongo.dnodeProtocol.Scrubber @proto.localStore
    scrubber.scrub [options, cb], =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method = method
      @proto.emit 'request', scrubbed

      # Remove the handler from proto when callback is called.
      # This is required to prevent unused callbacks to consume memory.
      if cb
        # id of the last callback function
        id = Number(Object.keys(scrubbed.callbacks).last)
        # original handler
        fn = @proto.localStore.items[id]
        # replace the handler. when called it will remove the handler.
        @proto.localStore.items[id] = ()=>
          delete @proto.localStore.items[id]
          fn.apply null, arguments

  onOpen: ->
    log "Connected to Kite: #{@kite.name}"
    @clearBackoffTimeout()
    @readyState = READY
    @emit 'connected', @name
    @emit 'ready'

  onClose: (evt)->
    log "#{@kite.name}: disconnected, trying to reconnect..."
    @readyState = CLOSED
    @emit 'disconnected'
    # enable below to autoReconnect when the socket has been closed
    if @autoReconnect
      KD.utils.defer => @setBackoffTimeout @bound "connect"

  onMessage: (evt)->
    data = evt.data
    log "onMessage", data
    req = JSON.parse data
    @proto.handle(req)

  onError: (evt)->
    log "#{@kite.name} error: #{evt.data}"

  initBackoff: (options)->
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

  ready: (cb)->
    return KD.utils.defer cb  if @readyState
    @once 'ready', cb
