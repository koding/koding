class KodingKite extends KDObject

  constructor: (options) ->
    super options

    { name } = options

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
