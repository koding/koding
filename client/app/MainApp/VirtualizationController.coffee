class VirtualizationController extends KDController

  constructor:->
    super
    @kc = KD.singletons.kiteController

  _cbWrapper:(callback, emitStateChanged)->
    return callback  unless emitStateChanged

    kallback = (rest...)=>
      @info (err, info)=>
        warn "[VM]", err  if err
        @emit 'StateChanged', err, info
      callback? rest...

    return kallback

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
    @run 'vm.info', callback, no