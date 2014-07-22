class EnvironmentMachineItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left', 'right']
    options.staticJoints       = ['right']

    options.allowedConnections =
      EnvironmentDomainItem : ['right']
      EnvironmentExtraItem  : ['left']

    super options, data

    @terminalIcon = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : "terminal"
      click       : @bound "openTerminal"

  contextMenuItems : ->
    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    vmName = @getData().hostnameAlias
    vmAlwaysOnSwitch = new VMAlwaysOnToggleButtonView null, {vmName}
    items =
      customView4         : vmAlwaysOnSwitch
      'Re-initialize VM'  :
        disabled          : KD.isGuest()
        callback          : ->
          {hostnameAlias} = @getData()
          KD.getSingleton("vmController").reinitialize hostnameAlias
          @destroy()
      'Open VM Terminal'  :
        callback          : =>
          @openTerminal()
          @destroy()
        separator         : yes
      'Update init script':
        separator         : yes
        callback          : @bound "showInitScriptEditor"
      'Delete'            :
        disabled          : KD.isGuest()
        separator         : yes
        action            : 'delete'
      customView3         : colorSelection

    return items

  openTerminal:->
    vmName = @getData().hostnameAlias
    KD.getSingleton("router").handleRoute "/Terminal", replaceState: yes
    KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes

  confirmDestroy:->
    KD.getSingleton('vmController').remove @getData().hostnameAlias, @bound "destroy"

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
    title = @getData().hostnameAlias
    [vm]  = title.split "."

    """
      <div class='details'>
        <span class='toggle'></span>
        <h3>#{vm}</h3>
        <a href="http://#{title}" target="_blank" title="#{title}">
          <span class='url'></span>
        </a>
        {{> @terminalIcon}}
        {{> @chevron}}
      </div>
    """
