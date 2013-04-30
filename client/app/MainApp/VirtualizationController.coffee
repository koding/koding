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

  askToTurnOn:(appName='', callback)->

    content = """To #{if appName then 'run' else 'do this'} <b>#{appName}</b>
                 you need to turn on your VM first, you can do that by
                 clicking '<b>Turn ON VM</b>' button below."""

    modal = new KDModalView
      title          : "Your VM is turned off"
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        'Turn ON VM' :
          style      : "modal-clean-green"
          callback   : =>
            @start =>
              modal.destroy()
              if appName
                @once 'StateChanged', ->
                  appManager.open appName
        Cancel       :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()
            callback?()

    modal.once 'KDModalViewDestroyed', -> callback?()
