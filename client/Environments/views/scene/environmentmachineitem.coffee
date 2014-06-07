class EnvironmentMachineItem extends EnvironmentItem

  JView.mixin @prototype

  constructor:(options={}, data)->

    options.cssClass           = 'machine busy'
    options.joints             = ['left']

    options.allowedConnections =
      EnvironmentDomainItem    : ['right']

    super options, data


    @terminalIcon = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : "terminal"
      click       : @bound "openTerminal"

    @progress = new KDProgressBarView
      cssClass : "progress"


    machine = @getData()

    {computeController} = KD.singletons

    computeController.on "build-#{machine._id}",   @bound 'invalidateMachine'
    computeController.on "destroy-#{machine._id}", @bound 'invalidateMachine'

    computeController.on "public-#{machine._id}", (event)=>

      if event.percentage?

        @progress.updateBar event.percentage

        if event.percentage < 100 then @setClass 'loading busy'
        else KD.utils.wait 1000, =>  @unsetClass 'loading busy'

      else

        @unsetClass 'busy'

      @updateState event.status

    computeController.info machine


  updateState:(status)->

    return unless status

    if status is 'Running'
    then @setClass 'running'
    else @unsetClass 'running'

    @getData().setAt "status.state", status


  invalidateMachine:(event)->

    if event.percentage is 100

      machine = @getData()
      KD.remote.api.JMachine.one machine._id, (err, newMachine)=>
        if err then warn ".>", err
        else @setData newMachine


  contextMenuItems: ->

    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    this_   = this
    machine = @getData()

    vmAlwaysOnSwitch = new VMAlwaysOnToggleButtonView

    items =

      customView1         : vmAlwaysOnSwitch

      'Build Machine'     :
        callback          : ->
          {computeController} = KD.singletons
          computeController.build machine
          @destroy()

      'Re-initialize VM'  :
        disabled          : KD.isGuest()
        callback          : ->
          new KDNotificationView
            title : "Not implemented yet!"
          @destroy()

      'Open VM Terminal'  :

        callback          : ->
          this_.openTerminal()
          @destroy()

        separator         : yes

      'Update init script':
        separator         : yes
        callback          : @bound "showInitScriptEditor"

      'Delete'            :
        disabled          : KD.isGuest()
        separator         : yes
        action            : 'delete'

      customView2         : colorSelection

    return items


  openTerminal:->

    vmName = @getData().hostnameAlias
    KD.getSingleton("router").handleRoute "/Terminal", replaceState: yes
    KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes


  confirmDestroy:->

    {computeController} = KD.singletons
    computeController.destroy @getData()


  showInitScriptEditor: ->

    modal =  new EditorModal
      editor              :
        title             : "VM Init Script Editor <span>(experimental)</span>"
        content           : @data.meta?.initScript or ""
        saveMessage       : "VM init script saved"
        saveFailedMessage : "Couldn't save VM init script"
        saveCallback      : (script, modal) =>
          KD.remote.api.JVM.updateInitScript @data.hostnameAlias, script, (err, res) =>
            if err
              modal.emit "SaveFailed"
            else
              modal.emit "Saved"
              @data.meta or= {}
              @data.meta.initScript = Encoder.htmlEncode modal.editor.getValue()


  pistachio:->

    {label, provider, ipAddress, status:{state} } = @getData()

    title = label or provider

    publicUrl = ""

    { NotInitialized, Terminated } = Machine.State

    if state not in [ NotInitialized, Terminated ] and ipAddress?

      publicUrl = """
        <a href="http://#{ipAddress}" target="_blank" title="#{ipAddress}">
          <span class='url'>#{ipAddress}</span>
        </a>
      """

    """
      <div class='details'>
        <span class='toggle'></span>
        <h3>#{title}</h3>
        #{publicUrl}
        {span.state{#(status.state)}}
        {{> @progress}}
        {{> @terminalIcon}}
        {{> @chevron}}
      </div>
    """
