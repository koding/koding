class KodingKite extends KDObject

  { @Error } = require 'kite'

  constructor: (options) ->
    super options

    { name } = options

  extractInfoFromWsEvent = (event)->
    {reason, code, wasClean, timestamp, type} = event

    return {reason, code, wasClean, timestamp, type}

  logTransportFailures:->
    @transport.ws.addEventListener 'close', (event)->
      params = extractInfoFromWsEvent event
      ErrorLog.create 'ws closed', params

    @transport.ws.addEventListener 'error', (event)->
      params = extractInfoFromWsEvent event
      ErrorLog.create 'ws error', params

  getTransport: -> @transport

  setTransport: (@transport) ->
    @transport.connect()
    @emit 'ready'

  tell: (rpcMethod, params, callback) ->
    @ready().then => @transport.tell rpcMethod, [params], callback

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) -> @tell rpcMethod, payload

  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }

  @constructors = {}

  connect:    -> @transport?.connect()
  disconnect: -> @transport?.disconnect()
