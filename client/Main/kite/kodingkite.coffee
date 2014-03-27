class KodingKite extends KDObject

  constructor: (options, data) ->
    super options, data

    { @kite } = options

  tell: (rpcMethod, params, callback) ->
    @kite.tell rpcMethod, params, callback

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (rest...) -> @tell rpcMethod, rest...

  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }

  @constructors = {}
