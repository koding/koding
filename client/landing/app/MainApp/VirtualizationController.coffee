class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.singletons.kiteController
    @dialogIsOpen = no
    @resetVMData()

  run:(vm, command, callback)->
    KD.requireLogin
      callback : =>
        @askForApprove command, (approved)=>
          if approved
            cb = unless command is 'vm.info' then @_cbWrapper vm, callback \
                 else callback
            @kc.run
              kiteName : 'os'
              method   : command
              vmName   : vm
            , cb
          else unless command is 'vm.info' then @info vm
      onFailMsg : "Login required to use VMs"  unless command is 'vm.info'
      onFail    : =>
        unless command is 'vm.info' then callback yes
        else callback null, state: 'STOPPED'
      silence   : yes

  _runWraper:(command, vm, callback)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    vm or= @getDefaultVmName vm
    @run vm, command, callback

  start:(vm, callback)->
    @_runWraper 'vm.start', vm, callback

  stop:(vm, callback)->
    @_runWraper 'vm.stop', vm, callback

  reinitialize:(vm, callback)->
    @_runWraper 'vm.reinitialize', vm, callback

  info:(vm, callback)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    vm or= @getDefaultVmName vm
    @_runWraper 'vm.info', vm, (err, info)=>
      warn "[VM-#{vm}]", err  if err
      @emit 'StateChanged', err, vm, info
      callback? err, vm, info
    , no

  getDefaultVmName:->
    {entryPoint} = KD.config
    currentGroup = if entryPoint?.type is 'group' then entryPoint.slug
    if not currentGroup or currentGroup is 'koding' then "koding~#{KD.nick()}"
    else currentGroup

  createGroupVM:(type='personal', callback)->
    defaultVMOptions = {cpu : 1, disk : 1, ram : 1}
    group = KD.singletons.groupsController.getCurrentGroup()

    group.fetchBundle (err, bundle)->
      switch type
        when 'personal'
          bundle.debit defaultVMOptions, callback
        else
          bundle.debitGroup defaultVMOptions, callback

  fetchVMs:(callback)->
    return callback null, @vms  if @vms.length > 0
    KD.remote.api.JVM.fetchVms (err, vms)=>
      @vms = vms  unless err
      callback err, vms

  fetchGroupVMs:(callback)->
    return callback null, @groupVms  if @groupVms.length > 0
    KD.remote.api.JVM.fetchVmsByContext (err, vms)=>
      @groupVms = vms  unless err
      callback err, vms

  resetVMData:->
    @vms = @groupVms = []

  # fixme GG!
  fetchTotalVMCount:(callback)->
    callback null, "0"

  # fixme GG!
  fetchTotalLoC:(callback)->
    callback null, "0"

  _cbWrapper:(vm, callback)->
    return (rest...)=>
      @info vm, callback? rest...

  createNewVM:->
    return  if @dialogIsOpen

    vmCreateCallback = (err, vm)->
      if err
        warn err
        return new KDNotificationView
          title : err.message or "Something bad happened while creating VM"
      else
        KD.singletons.finderController.mountVm vm.name
      modal.destroy()

    group = KD.singletons.groupsController.getGroupSlug()

    buttons =
      'Create a Personal VM' :
        style    : "modal-clean-gray"
        callback : => @createGroupVM 'personal', vmCreateCallback

    if "owner" in KD.config.roles or "admin" in KD.config.roles
      content = """You can create a <b>Personal</b> or <b>Shared</b> VM for
                   <b>#{group}</b>. If you prefer to create a shared VM, all
                   members in <b>#{group}</b> will be able to use that VM.
                """
      buttons['Create a Shared VM'] =
        style      : "modal-clean-gray"
        callback   : => @createGroupVM 'shared', vmCreateCallback

    else if "member" in KD.config.roles
      content = """You can create a <b>Personal</b> VM in <b>#{group}</b>."""

    else
      return new KDNotificationView
        title : "You are not authorized to create VMs in #{group} group"

    buttons.Cancel =
      style      : "modal-cancel"
      callback   : -> modal.destroy()

    modal     = new KDModalView
      title   : "Create a new VM"
      content : "<div class='modalformline'><p>#{content}</p></div>"
      height  : "auto"
      overlay : yes
      buttons : buttons

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

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

    return  if @dialogIsOpen

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

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

  askToTurnOn:(appName='', callback)->

    return  if @dialogIsOpen

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

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no
