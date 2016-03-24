kd                      = require 'kd'
KDButtonView            = kd.ButtonView
KDView                  = kd.View
ComputePlansModal       = require './computeplansmodal'
CustomLinkView          = require '../customlinkview'
CustomPlanStorageSlider = require './customplanstorageslider'


module.exports = class ComputeResizeModal extends ComputePlansModal

  constructor: (options = {}, data) ->

    options.cssClass = 'resize-modal'
    options.height   = 320

    super options, data

    { @machine } = @getOptions()

  viewAppended: ->

    { usage, limits, plan, reward } = @getOptions()

    # Add reward on top of current plan storage limit
    maxStorage = limits.storage + reward

    remaining = Math.max 0, maxStorage - usage.storage
    @machineCurrentStorage = @machine.jMachine.meta?.storage_size or 3
    newPossibleStorage = @machineCurrentStorage + remaining

    @addSubView content = new KDView
      cssClass : 'container'

    rewardTip = if reward > 0 \
      then "<br>and you have #{reward}GB extra storage from referrals" else ''

    content.addSubView title = new KDView
      cssClass    : 'modal-title'
      partial     : "
        Remaining disk usage:
          <strong>#{remaining}</strong> GB / #{maxStorage} GB"
      tooltip     :
        placement : 'top'
        title     : "
          Current plan: '#{plan}' has #{limits.storage}GB storage#{rewardTip}
        "


    title.setClass 'warn'  if usage.storage >= maxStorage

    content.addSubView storageContainer = new KDView
      cssClass : 'storage-container'

    storageContainer.addSubView new KDView
      cssClass : 'container-title'
      partial  : "Resizing vm <strong>#{@machine.label}</strong>"

    storageContainer.addSubView @storageSlider = new CustomPlanStorageSlider
      cssClass : 'storage-slider'
      maxValue : maxStorage + 10
      minValue : @machineCurrentStorage
      handles  : [newPossibleStorage]

    storageContainer.addSubView @usageTextView = new KDView

    content.addSubView @resizeVMButton = new KDButtonView
      title    : 'Resize VM'
      style    : 'solid medium green'
      loader   : yes
      callback : @bound 'resizeVM'
      disabled : newPossibleStorage <= @machineCurrentStorage

    content.addSubView new CustomLinkView
      title    : 'Upgrade your account for more storage'
      href     : '/Pricing'

    @updateUsageText newPossibleStorage, usage, maxStorage

    @storageSlider.on 'ValueIsChanging', (val) =>
      @updateUsageText val, usage, maxStorage


  updateUsageText: (val, usage, maxStorage) ->

    newUsage = (usage.storage + val) - @machineCurrentStorage

    if newUsage > maxStorage
      @usageTextView.setClass 'warn'
      @resizeVMButton.disable()
    else
      @usageTextView.unsetClass 'warn'
      @resizeVMButton.enable()  unless usage.storage >= maxStorage

    if newUsage is @machineCurrentStorage
      # If not resized before disable to resize for minimum storage
      # but for higher values allow user to call resize for the same
      # storage size since we need that if somehow resize fails once ~GG
      @resizeVMButton.disable()  if @machineCurrentStorage is 3
      @usageTextView.updatePartial "
        Currently <strong>#{@machine.label}</strong>
        has <strong>#{@machineCurrentStorage}GB</strong> storage
      "
    else
      @usageTextView.updatePartial "
        You will be using
        <strong>#{newUsage}GB/#{maxStorage}GB</strong> storage
      "


  resizeVM: ->

    { machine }           = @getOptions()
    { computeController } = kd.singletons

    resizeTo = @storageSlider.handles.first.value

    computeController.resize machine, resizeTo

    @destroy()
