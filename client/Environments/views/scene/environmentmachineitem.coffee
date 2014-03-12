class EnvironmentMachineItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left', 'right']
    options.staticJoints       = ['right']

    options.allowedConnections =
      EnvironmentDomainItem : ['right']
      EnvironmentExtraItem  : ['left']

    super options, data

    # @ramUsage  = new VMRamUsageBar  null, data.title
    # @diskUsage = new VMDiskUsageBar null, data.title

  contextMenuItems : ->
    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    vmName = @getData().vm.hostnameAlias
    # vmStateSwitch    = new NVMToggleButtonView        null, {vmName}
    vmAlwaysOnSwitch = new VMAlwaysOnToggleButtonView null, {vmName}
    # vmMountSwitch = new NMountToggleButtonView {}, {vmName}
    items =
      # customView1        : vmStateSwitch
      customView4        : vmAlwaysOnSwitch
      # customView2        : vmMountSwitch
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
    vmName = @getData().vm.hostnameAlias
    KD.getSingleton("router").handleRoute "/Terminal", replaceState: yes
    KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes

  confirmDestroy:->
    (KD.getSingleton 'vmController').remove @getData().vm.hostnameAlias, @bound "destroy"

  click:(event)->

    target = $(event.target)
    if target.is ".terminal"
      @openTerminal()
      return no

    super


  pistachio:->
    {vm: { hostnameAlias: title }} = @getData()
    vm = (title.split '.').first
    """
      <div class='details'>
        <span class='toggle'></span>
        <h3>#{vm}</h3>
        <a href="http://#{title}" target="_blank" title="#{title}">
          <span class='url'></span>
        </a>
        <span class='terminal'></span>
        <span class='chevron'></span>
      </div>
    """
