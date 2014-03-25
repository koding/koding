class KDKite extends Kite

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (rest...) -> @tell2 rpcMethod, rest...

  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }

  @constructors = {}

  createProperError = (err) ->
    e = new Error err.message
    e.type = err.type
    e

  tell2: (method, params = {}) ->
    # #tell2 is wrapping #tell with a promise-based api
    new Promise (resolve, reject) =>

      { correlationName, kiteName, timeout: classTimeout } = @getOptions()

      options = {
        method
        kiteName
        correlationName
        withArgs: params
      }

      # handle timeout:
      timeOk = yes
      if params?.timeout not in [null, Infinity]
        timeout = params?.timeout ? classTimeout ? 5000
        KD.utils.wait timeout, ->
          timeOk = no
          reject new Error "Request timeout exceeded (#{ timeout }ms)"

      callback = (err, restResponse...) ->
        return reject createProperError err   if err?
        return resolve restResponse...        if timeOk

      @tell options, callback

  createProperError = (err) ->
    e = new Error err.message
    e.type = err.type
    e
