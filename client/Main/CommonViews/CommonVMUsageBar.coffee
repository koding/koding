class CommonVMUsageBar extends KDProgressBarView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "vm-usage-bar", options.cssClass
    super options, data

  decorateUsage: (usage) ->
    {label} = @getOptions()
    ratio = ((usage.current * 100) / usage.max).toFixed(2)
    @updateBar ratio, '%', label

    if usage.max is 0
      title =  "Failed to fetch #{label} info"
    else
      for key, item of usage
        usage[key] = KD.utils.formatBytesToHumanReadable item

    @setTooltip
      title     : title or "#{usage.current} of #{usage.max}"
      placement : "bottom"
      delayIn   : 300
      offset    :
        top     : 2
        left    : -8

  fetchUsage: ->

  viewAppended: ->
    super
    @fetchUsage @bound "decorateUsage"

class VMRamUsageBar extends CommonVMUsageBar
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "ram", options.cssClass
    options.label    = "RAM"
    super options, data

  fetchUsage: (callback) ->
    KD.getSingleton("vmController").fetchRamUsage @getData(), callback

class VMDiskUsageBar extends CommonVMUsageBar
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "disk", options.cssClass
    options.label    = "DISK"
    super options, data

  fetchUsage: (callback) ->
    KD.getSingleton("vmController").fetchDiskUsage @getData(), callback
