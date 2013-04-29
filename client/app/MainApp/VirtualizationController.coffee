class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.singletons.kiteController

    @lastState =
      state    : 'STOPPED'

  run:(command, callback, emitStateChanged=yes)->
    @kc.run
      kiteName : 'os'
      method   : command
    , @_cbWrapper callback, emitStateChanged

  start:(callback)->
    @run 'vm.start', callback

  stop:(callback)->
    @run 'vm.stop', callback

  reinitialize:(callback)->
    @run 'vm.reinitialize', callback

  info:(callback)->
    @run 'vm.info', (err, info)=>
      unless err then @lastState = info
      else warn "[VM]", err

      @emit 'StateChanged', err, info
      callback? err, info
    , no

  _cbWrapper:(callback, emitStateChanged)->
    return callback  unless emitStateChanged
    return (rest...)=>
      @info callback? rest...

