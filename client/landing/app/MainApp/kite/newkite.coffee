# NewKite is a class for communicating with a remote Kite.
# It is analogous to RemoteKite class in go/koding/newkite/kite/remote.go file.
class NewKite extends KDObject

  [NOTREADY, READY, CLOSED] = [0,1,3]

  # includes from: libs/dnode-protocol.js
  # made it with: http://browserify.org
  # downloaded from: http://wzrd.in/bundle/dnode-protocol@latest
  proto = require "dnode-protocol"

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

    @proto = proto @handlers
    @proto.on 'request', (req)=>
      log "proto request", {req}
      @ready =>
        @ws.send JSON.stringify req
    @proto.on 'fail', (err)=>
      log "proto fail", {err}
    @proto.on 'error', (err)=>
      log "proto error", {err}

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

    scrub = @proto.scrubber.scrub [options, cb]

    @proto.emit 'request',
        method    : method
        arguments : scrub.arguments
        callbacks : scrub.callbacks
        links     : scrub.links

    # Remove the handler from proto when callback is called.
    # This is required to prevent unused callbacks to consume memory.
    if cb
      # id of the last callback function
      id = Number(Object.keys(scrub.callbacks).last)
      # original handler
      fn = @proto.callbacks.local[id]
      # replace the handler. when called it will remove the handler.
      @proto.callbacks.local[id] = ()=>
        delete @proto.callbacks.local[id]
        @proto.apply fn, arguments

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
