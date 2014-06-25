class EnvironmentMachineItem extends EnvironmentItem

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

    { label, provider, uid, status } = machine = @getData()
    { computeController } = KD.singletons

    { Running, NotInitialized, Terminated } = Machine.State

    @addSubView new KDCustomHTMLView
      partial : "<span class='toggle'></span>"

    @addSubView @title = new KDCustomHTMLView
      partial : "<h3>#{label or provider or uid}</h3>"

    @addSubView @ipAddress = new KDCustomHTMLView
      partial  : @getIpLink()

    @addSubView @state = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "state"

    @addSubView @statusToggle = new KodingSwitch
      cssClass     : "tiny"
      defaultValue : status.state is Running
      callback     : (state)->
        if state
        then computeController.start machine
        else computeController.stop machine

    @addSubView @progress = new KDProgressBarView
      cssClass : "progress"

    @addSubView @terminalIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "terminal"
      click    : @lazyBound "openTerminal", {}

    if status.state in [ NotInitialized, Terminated ]
      @addSubView @initView = new InitializeMachineView
      @initView.on "Initialize", ->
        computeController.build machine
        @setClass 'hidden-all'

    computeController.on "build-#{machine._id}",   @bound 'invalidateMachine'
    computeController.on "destroy-#{machine._id}", @bound 'invalidateMachine'

    computeController.on "public-#{machine._id}", (event)=>

      if event.percentage?

        @progress.updateBar event.percentage

        if event.percentage < 100 then @setClass 'loading busy'
        else return KD.utils.wait 1000, =>
          @unsetClass 'loading busy'
          @updateState event

      else

        @unsetClass 'loading busy'

      @updateState event

    computeController.info machine


  updateState:(event)->

    {status, reverted} = event

    return unless status

    {Running, Starting, NotInitialized, Terminated} = Machine.State

    if reverted
      warn "State reverted!"
      if status in [ NotInitialized, Terminated ] and @initView?
        @initView.unsetClass 'hidden-all'

    @unsetClass stateClasses
    @setClass status.toLowerCase()

    if status in [ Running, Starting ]
    then @statusToggle.setOn no
    else @statusToggle.setOff no

    @getData().jMachine.setAt "status.state", status
    @state.updatePartial status


  invalidateMachine:(event)->

    if event.percentage is 100

      machine = @getData()
      KD.remote.api.JMachine.one machine._id, (err, newMachine)=>
        if err then warn ".>", err
        else
          @setData newMachine
          @ipAddress.updatePartial @getIpLink()


  contextMenuItems: ->

    machine = @getData()

    return if KD.isGuest()

    buildReady = machine.status.state in [
      Machine.State.NotInitialized
      Machine.State.Terminated
    ]

    isRunning  = machine.status.state is Machine.State.Running

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
        callback          : @bound "runBuildScript"
        separator         : yes

      'Launch Terminal'   :
        disabled          : !isRunning
        callback          : @lazyBound "openTerminal", {}
        separator         : yes

      'Delete'            :
        disabled          : KD.isGuest()
        action            : 'delete'
        separator         : yes

      customView2         : colorSelection

    return items


  openTerminal:(options = {})->

    options.machine = @getData()
    new TerminalModal options


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

    machine = @getData()

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


  runBuildScript: ->

    machine = @getData()

    { status: { state } } = machine
    unless state is Machine.State.Running
      return new KDNotificationView
        title : "Machine is not running."

    @reviveProvisioner (err, provisioner)=>

      if err or not provisioner
        return new KDNotificationView
          title : "Failed to fetch build script."

      {content: {script}} = provisioner
      script = Encoder.htmlDecode script

      path = provisioner.slug.replace "/", "-"
      path = "/tmp/init-#{path}"
      machine.fs.create { path }, (err, file)=>

        if err or not file
          return new KDNotificationView
            title : "Failed to upload build script."

        script += "\necho $?|kdevent;rm -f #{path};exit"

        file.save script, (err)=>
          return if KD.showError err

          modal = @openTerminal
            command       : "bash #{path};exit"
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


  getIpLink:->

    { ipAddress, status:{state} } = @getData().jMachine
    { Running, Rebooting } = Machine.State

    if ipAddress? and state in [ Running, Rebooting ]

      """
        <a href="http://#{ipAddress}" target="_blank" title="#{ipAddress}">
          <span class='url'>#{ipAddress}</span>
        </a>
      """

    else ""
