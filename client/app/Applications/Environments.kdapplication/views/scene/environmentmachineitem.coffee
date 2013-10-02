class EnvironmentMachineItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left']
    options.allowedConnections =
      EnvironmentDomainItem : ['right']

    super options, data

    vmName = @getData().title
    @memUsage = new KDProgressBarView
    @diskUsage = new KDProgressBarView

  contextMenuItems : ->

    colorSelection = new ColorSelection
      selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    vmName = @getData().title
    vmStateSwitch = new NVMToggleButtonView {}, {vmName}
    vmMountSwitch = new NMountToggleButtonView {}, {vmName}
    items =
      customView1        : vmStateSwitch
      customView2        : vmMountSwitch
      'Re-initialize VM' :
        disabled         : KD.isGuest()
        callback         : ->
          KD.getSingleton("vmController").reinitialize vmName
          @destroy()
      'Open VM Terminal' :
        callback         : ->
          KD.getSingleton("appManager").open "WebTerm", params: {vmName}, forceNew: yes
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

  viewAppended:->
    super
    @updateUsageInfo()

  updateUsageInfo:->
    @usageFetcher 'fetchRamUsage', @memUsage, 'RAM'
    @usageFetcher 'fetchDiskUsage', @diskUsage, 'DISK'

  usageFetcher: (method, widget, label)->
    vm  = @getData().title
    vmc = KD.getSingleton 'vmController'
    vmc[method] vm, (usage)->
      ratio = ((usage.current * 100) / usage.max).toFixed(2)
      widget.updateBar ratio, '%', label

      if usage.max is 0
        title =  "Failed to fetch #{label} info"
      else
        for key, item of usage
          usage[key] = KD.utils.formatBytesToHumanReadable item

      widget.setTooltip
        title     : title or "#{usage.current} of #{usage.max}"
        placement : "bottom"
        delayIn   : 300
        offset    :
          top     : 2
          left    : -8

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{> @memUsage}}
        {{> @diskUsage}}
        <span class='chevron'></span>
      </div>
    """