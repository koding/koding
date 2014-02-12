# NewKite is a class for communicating with a remote Kite.
# It is analogous to RemoteKite class in go/koding/newkite/kite/remote.go file.
class NewKite extends KDObject

  {setAt} = Bongo.JsPath
  [NOTREADY, READY, CLOSED] = [0,1,3]

  constructor: (kite, authentication, options={})->
    super options

    @kite = kite
    @authentication = authentication

    @readyState = NOTREADY
    @autoReconnect = true

    @initBackoff options  if @autoReconnect

    @handlers =
      log   : (options)->
        log options.withArgs...
        options.responseCallback({withArgs: [{error: null, result: null}]})
      alert : (options)->
        alert options.withArgs...
        options.responseCallback({withArgs: [{error: null, result: null}]})

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
    addr = @kite.url
    log "Trying to connect to #{addr}"
    @ws = new WebSocket addr
    @ws.onopen    = @bound 'onOpen'
    @ws.onclose   = @bound 'onClose'
    @ws.onmessage = @bound 'onMessage'
    @ws.onerror   = @bound 'onError'

  disconnect: (reconnect=true)->
    @autoReconnect = !!reconnect  if reconnect?
    @ws.close()

  # Call a method on the connected Kite.
  tell: (method, args, cb) ->
    # some methods doesn't need any argument(s), therefore you can omit args
    # completely. If you omit args, then you'll going to pass cb as the second
    # argument to the function, therefore we'll assign it back to cb and make
    # args empty.
    [args, cb] = [[], args] unless cb

    if not Array.isArray(args)
      args = [args]

    options =
      authentication   : @authentication
      withArgs         : args
      responseCallback : cb

    # Normally the request is made with the following statement:
    #   @proto.request method, [options, cb]
    # However, we are making a single request/response call and
    # there is no point to hold the callback function because it
    # will never be called again. That's why we are deleting to
    # free the memory with the code below.
    scrubber = new Bongo.dnodeProtocol.Scrubber @proto.localStore
    scrubber.scrub [options], =>
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
          response = arguments[0]
          fn.apply null, [response.error, response.result]

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

    getCallback = (callbackId) =>
      unless @proto.remoteStore.has callbackId
        @proto.remoteStore.add callbackId, =>
          @proto.request callbackId, [].slice.call arguments
      cb = @proto.remoteStore.get callbackId
      return (rest...) =>
        cb withArgs:rest

    args = req.arguments or []
    Object.keys(req.callbacks or {}).forEach (strId)->
      id = parseInt strId, 10
      path = req.callbacks[id]

      callback = getCallback id

      callback.id = id
      setAt args, path, callback

    {method} = req
    switch method
      when 'methods'
        @proto.handleMethods args[0]
      when 'error'
        @proto.emit 'remoteError', args[0]
      when 'cull'
        args.forEach (id)=> @proto.remoteStore.cull id
      else
        switch typeof method
          when 'string'
            if @proto.instance.propertyIsEnumerable method
              apply @proto.instance[method], @proto.instance, args
            else
              @proto.emit 'error', new Error(
                "Request for non-enumerable method: #{method}"
              )
          when 'number'
            apply @proto.localStore.get(method), @proto.instance, args[0].withArgs

  apply =(fn, ctx, args)-> fn.apply ctx, args

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
