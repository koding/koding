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
      customView4        : vmAlwaysOnSwitch
      'Re-initialize VM' :
        disabled         : KD.isGuest()
        callback         : ->
          KD.getSingleton("vmController").reinitialize vmName
          @destroy()
      'Open VM Terminal' :
        callback         : =>
          @openTerminal()
          @destroy()
        separator        : yes
      'Delete'           :
        disabled         : KD.isGuest()
        separator        : yes
        action           : 'delete'
      'Unfocus'          :
        separator        : yes
        action           : 'unfocus'
      customView3        : colorSelection

    return items

  openTerminal:->
    vmName = @getData().hostnameAlias
    KD.getSingleton("router").handleRoute "/Terminal", replaceState: yes
    KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes

  confirmDestroy:->
    KD.getSingleton('vmController').remove @getData().hostnameAlias, @bound "destroy"

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
