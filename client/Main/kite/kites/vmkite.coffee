class KodingKite_VmKite extends KodingKite

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload  = {}) ->
      @tell rpcMethod, payload

  tell: (method, payload = {}) ->
    payload.vmName = @options.correlationName
    payload.groupId = @options.groupId
    super method, payload