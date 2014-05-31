class KDKite extends Kite

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (rest...) -> @tell rpcMethod, rest...

  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }

  @constructors = {}

  createProperError = (err) ->
    e = new Error err.message
    e.type = err.type
    e.name = err.type
    e.code = err.code
    e

  tell: (method, params = {}) ->
    { correlationName, kiteName, timeout: classTimeout } = @getOptions()

    options = @getOptions()

    new Promise (resolve, reject) =>

      options = {
        method
        kiteName
        correlationName
        withArgs: params
      }

      callback = (err, restResponse...) ->
        return reject createProperError err   if err?
        return resolve restResponse...

      # I don't care how bad this is.  This class should be removed soon.
      KD.singletons.vmController.fetchVmInfo correlationName, (err, vm) =>
        return reject err  if err?

        # we need the groupId, but because of bad application design, there
        # isn't a convenient way to inject it other than this.  These problems
        # are fixed with the new kite infrastructure.
        options.withArgs.groupId = vm.groupId

        # .tellOld is deprecated, but still used internally here temporarily
        @tellOld options, callback

    .timeout classTimeout ? 15000
