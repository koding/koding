class EnvironmentMachineItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left']
    if KD.checkFlag 'nostradamus' then options.joints.push 'right'

    options.allowedConnections =
      EnvironmentDomainItem : ['right']
      EnvironmentExtraItem  : ['left']

    super options, data

    @ramUsage  = new VMRamUsageBar  null, data.title
    @diskUsage = new VMDiskUsageBar null, data.title

  contextMenuItems : ->
    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    vmName = @getData().title
    vmStateSwitch    = new NVMToggleButtonView        null, {vmName}
    vmAlwaysOnSwitch = new VMAlwaysOnToggleButtonView null, {vmName}
    # vmMountSwitch = new NMountToggleButtonView {}, {vmName}
    items =
      customView1        : vmStateSwitch
      customView4        : vmAlwaysOnSwitch
      # customView2        : vmMountSwitch
      'Re-initialize VM' :
        disabled         : KD.isGuest()
        callback         : ->
          KD.getSingleton("vmController").reinitialize vmName
          @destroy()
      'Open VM Terminal' :
        callback         : ->
          KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes
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

  confirmDestroy:->
    (KD.getSingleton 'vmController').remove @getData().title, @bound "destroy"

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{> @ramUsage}}
        {{> @diskUsage}}
        <span class='chevron'></span>
      </div>
    """
