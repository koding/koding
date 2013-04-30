class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.singletons.kiteController

    @lastState =
      state    : 'STOPPED'

  run:(command, callback)->

    @askForApprove command, (approved)=>
      if approved
        cb = unless command is 'vm.info' then @_cbWrapper callback \
             else callback
        @kc.run
          kiteName : 'os'
          method   : command
        , cb
      else unless command is 'vm.info' then @info()

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

  _cbWrapper:(callback)->
    return (rest...)=>
      @info callback? rest...

  askForApprove:(command, callback)->

    switch command
      when 'vm.stop'
        content = """Turning off your VM will <b>stop</b> running Terminal
                     instances and all running proccesess that you have on
                     your VM. Do you want to continue?"""
        button  =
          title : "Turn off"
          style : "modal-clean-red"

      when 'vm.reinitialize'
        content = """Re-initializing your VM will <b>reset</b> all of your
                     settings that you've done in root filesystem. This
                     process will not remove any of your files under your
                     home directory. Do you want to continue?"""
        button  =
          title : "Re-initialize"
          style : "modal-clean-red"

      else
        return callback yes

    modal = new KDModalView
      title          : "Approval required"
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Action       :
          title      : button.title
          style      : button.style
          callback   : ->
            modal.destroy()
            callback yes
        Cancel       :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()
            callback no

    modal.once 'KDModalViewDestroyed', -> callback no

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
