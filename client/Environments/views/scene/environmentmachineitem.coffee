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
      click    : @bound "openTerminal"

    if status.state in [ NotInitialized, Terminated ]
      @addSubView initView = new InitializeMachineView
      initView.once "Initialize", ->
        computeController.build machine
        initView.destroy()

    computeController.on "build-#{machine._id}",   @bound 'invalidateMachine'
    computeController.on "destroy-#{machine._id}", @bound 'invalidateMachine'

    computeController.on "public-#{machine._id}", (event)=>

      if event.percentage?

        @progress.updateBar event.percentage

        if event.percentage < 100 then @setClass 'loading busy'
        else return KD.utils.wait 1000, =>
          @unsetClass 'loading busy'
          @updateState event.status

      else

        @unsetClass 'loading busy'

      @updateState event.status

      if event.reverted
        warn "State reverted!"

    computeController.info machine


  updateState:(status)->

    return unless status

    {Running, Starting} = Machine.State

    @unsetClass stateClasses
    @setClass status.toLowerCase()

    if status in [Running, Starting]
    then @statusToggle.setOn no
    else @statusToggle.setOff no

    @getData().setAt "status.state", status
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

    this_ = this

    items =

      'Build Machine'     :
        disabled          : !buildReady
        callback          : ->
          {computeController} = KD.singletons
          computeController.build machine
          @destroy()

      'Open VM Terminal'  :

        disabled          : !isRunning
        callback          : ->
          this_.openTerminal()
          @destroy()

        separator         : yes

      'Update provisioner':
        separator         : yes
        callback          : @bound "prepareProvisionEditor"

      'Delete'            :
        disabled          : KD.isGuest()
        separator         : yes
        action            : 'delete'

      customView2         : colorSelection

    return items


  openTerminal:->

    machine = new Machine machine: @getData()
    modal   = new TerminalModal { machine }

  confirmDestroy:->

    {computeController} = KD.singletons
    computeController.destroy @getData()


  prepareProvisionEditor: ->

    machine     = @getData()
    provisioner = machine.provisioners.first

    if provisioner

      {JProvisioner} = KD.remote.api
      JProvisioner.one slug: provisioner, (err, revivedProvisioner)=>

        return if KD.showError err
        @showEditorModalFor revivedProvisioner

    else @showEditorModalFor()


  showEditorModalFor: (provisioner)->

    modal =  new EditorModal

      editor              :
        title             : "Machine Init Script Editor <span>(experimental)</span>"
        content           : provisioner?.content?.script or ""
        saveMessage       : "Machine init script saved"
        saveFailedMessage : "Couldn't save Machine init script"

        saveCallback      : (script, modal) ->

          provisioner.update content: { script }, (err,res)->

            if err
              modal.emit "SaveFailed"
            else
              modal.emit "Saved"

    # information = new KDNotificationView
    #   container     : modal
    #   type          : "tray"
    #   content       : "Lorem ipsum dolor sen de affet."
    #   duration      : 0
    #   closeManually : no


  getIpLink:->

    { ipAddress, status:{state}  } = @getData()
    { Running, Rebooting } = Machine.State

    if ipAddress? and state in [ Running, Rebooting ]

      """
        <a href="http://#{ipAddress}" target="_blank" title="#{ipAddress}">
          <span class='url'>#{ipAddress}</span>
        </a>
      """

    else ""
