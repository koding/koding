class EnvironmentMachineItem extends EnvironmentItem

  # TODO: move functionality to delegate ~ GG

  stateClasses = ""
  for state in Object.keys Machine.State
    stateClasses += "#{state.toLowerCase()} "

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left']

    options.allowedConnections =
      EnvironmentDomainItem    : ['right']

    super options, data

  viewAppended: ->

    machine = @getData()
    @addSubView @machineItem = new MachineItem {}, machine

    { computeController } = KD.singletons

    computeController.on "build-#{machine._id}",   @bound 'invalidateMachine'
    computeController.on "destroy-#{machine._id}", @bound 'invalidateMachine'


  invalidateMachine:(event)->

    if event.percentage is 100

      machine = @machineItem.getData()
      KD.remote.api.JMachine.one machine._id, (err, newMachine)=>
        if err then warn ".>", err
        else
          @machineItem.setData new Machine machine: newMachine
          @machineItem.ipAddress.updatePartial @machineItem.getIpLink()

        if /^build/.test event.eventId
          KD.utils.wait 3000, =>
            new KDNotificationView
              title: "Preparing to run init script..."
            @runBuildScript()


  contextMenuItems: ->

    machine = @machineItem.getData()

    return if KD.isGuest()

    buildReady = machine.status.state in [
      Machine.State.NotInitialized
      Machine.State.Terminated
    ]

    running  = machine.status.state is Machine.State.Running

    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items =

      'Build Machine'     :
        disabled          : !buildReady
        callback          : ->
          {computeController} = KD.singletons
          computeController.build machine
          @destroy()

      'Update build script':
        callback          : @bound "showBuildScriptEditorModal"

      'Run build script'  :
        disabled          : !running
        separator         : yes

      'Launch Terminal'   :
        disabled          : !running
        callback          : @machineItem.lazyBound "openTerminal", {}
        separator         : yes

      'Delete'            :
        disabled          : KD.isGuest()
        action            : 'delete'
        separator         : yes

      customView2         : colorSelection

    if running
      items['Run build script'].children =
        'Inside a terminal' :
          callback        : @lazyBound "runBuildScript", inTerminal = yes
        'As background process' :
          callback        : @lazyBound "runBuildScript", inTerminal = no

    return items


  confirmDestroy:->

    {computeController} = KD.singletons
    computeController.destroy @getData()


  showInformation = do ->

    information = null

    (provisioner, modal)->

      if provisioner?
        message = "Build script <strong>#{provisioner.slug}</strong> loaded. "
        unless KD.isMine provisioner
          message += """When you edit it, it won't change the original,
                        it will create your own copy of this build script."""
      else
        message = """This is a new build script. This bash script will be
                     executed as root when the machine is rebuilt."""

      information?.destroy?()
      information = new KDNotificationView
        container     : modal
        type          : "tray"
        content       : message
        duration      : 0
        closeManually : no


  reviveProvisioner: (callback)->

    machine     = @getData()
    provisioner = machine.provisioners.first

    return callback null  unless provisioner

    {JProvisioner} = KD.remote.api
    JProvisioner.one slug: provisioner, callback


  showBuildScriptEditorModal: ->

    machine = @machineItem.getData()

    @reviveProvisioner (err, provisioner)->

      return  if KD.showError err

      modal   = new EditorModal

        editor              :
          title             : "Build Script Editor"
          content           : provisioner?.content?.script or ""
          saveMessage       : "Build script saved"
          saveFailedMessage : "Couldn't save build script"

          saveCallback      : (script, modal)->

            if KD.isMine provisioner

              provisioner.update content: { script }, (err, res)->
                modal.emit if err then "SaveFailed" else "Saved"

            else

              {JProvisioner} = KD.remote.api
              JProvisioner.create
                type    : "shell"
                content : { script }
              , (err, newProvisioner)->

                return  if KD.showError err

                machine.jMachine.setProvisioner newProvisioner.slug, (err)->
                  modal.emit if err then "SaveFailed" else "Saved"

                  unless KD.showError err
                    machine.provisioners = [ newProvisioner.slug ]
                    provisioner          = newProvisioner
                    showInformation provisioner, modal


      showInformation provisioner, modal


  runBuildScript: (inTerminal = yes)->

    machine = @machineItem.getData()

    { status: { state } } = machine
    unless state is Machine.State.Running
      return new KDNotificationView
        title : "Machine is not running."

    # There is a race condition for new machines
    # which doesn't have correct stack as @parent
    # FIXME ~ GG
    envVariables = ""
    for key, value of @parent.getData().config or {}
      envVariables += """export #{key}="#{value}"\n"""

    @reviveProvisioner (err, provisioner)=>

      if err
        return new KDNotificationView
          title : "Failed to fetch build script."
      else if not provisioner
        return new KDNotificationView
          title : "Provision script is not set."

      {content: {script}} = provisioner
      script = Encoder.htmlDecode script

      path = provisioner.slug.replace "/", "-"
      path = "/tmp/init-#{path}"
      machine.fs.create { path }, (err, file)=>

        if err or not file
          return new KDNotificationView
            title : "Failed to upload build script."

        script  = "#{envVariables}\n\n#{script}\n"
        script += "\necho $?|kdevent;rm -f #{path};exit"

        file.save script, (err)=>
          return if KD.showError err

          command = "bash #{path};exit"

          if not inTerminal

            new KDNotificationView
              title: "Init script running in background..."

            machine.getBaseKite().exec { command }
              .then (res)->

                new KDNotificationView
                  title: "Init script executed"

                info  "Init script executed : ", res.stdout  if res.stdout
                error "Init script failed   : ", res.stderr  if res.stderr

              .catch (err)->

                new KDNotificationView
                  title: "Init script executed successfully"
                error "Init script failed:", err

            return

          modal = @machineItem.openTerminal
            title         : "Running init script for #{machine.getName()}..."
            command       : command
            readOnly      : yes
            destroyOnExit : no

          modal.once "terminal.event", (data)->

            if data is "0"
              title   = "Installed successfully!"
              content = "You can now safely close this Terminal."
            else
              title   = "An error occured."
              content = """Something went wrong while running build script.
                           Please try again."""

            new KDNotificationView {
              title, content
              type          : "tray"
              duration      : 0
              container     : modal
              closeManually : no
            }

