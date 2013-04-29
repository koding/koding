class VirtualizationController extends KDController

  constructor:->
    super
    @kc = KD.singletons.kiteController

  run:(command, callback)->
    @kc.run
      kiteName : 'os'
      method   : command
    , callback

  start:(callback)->
    @run 'vm.start', callback

  stop:(callback)->
    @run 'vm.stop', callback

  info:(callback)->
    @run 'vm.info', callback
