class KodingKite_VmKite extends KodingKite
  
  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload  = {}) ->
      payload.vmName = @options.correlationName
      @tell rpcMethod, payload
