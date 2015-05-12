globals                 = require 'globals'
showError               = require '../util/showError'
kd                      = require 'kd'
KDButtonView            = kd.ButtonView
KDSelectBox             = kd.SelectBox
KDView                  = kd.View
ComputePlansModal       = require './computeplansmodal'
CustomLinkView          = require '../customlinkview'
CustomPlanStorageSlider = require './customplanstorageslider'
trackEvent              = require 'app/util/trackEvent'
remote                  = require('../remote').getInstance()


module.exports = class ComputePlansModalPaid extends ComputePlansModal

  ###*
   * @param {Object} options
   * @param {String} options.snapshotId - The snapshot to automatically
   *  select in the snapshot list.
  ###
  constructor:(options = {}, data)->

    options.cssClass = 'paid-plan'

    super options, data

  viewAppended:->

    { usage, limits, plan } = @getOptions()

    @addSubView content = new KDView
      cssClass : 'container'

    remaining = Math.max 0, limits.total - usage.total

    content.addSubView title = new KDView
      cssClass : "modal-title"
      partial  : """
        Remaining VM slots:
          <strong>
            #{remaining}/#{limits.total}
          </strong>
      """

    title.setClass 'warn'  if usage.total >= limits.total

    content.addSubView regionContainer = new KDView
      cssClass : "regions-container"

    regionContainer.addSubView new KDView
      cssClass : "container-title"
      partial  : "choose vms region"

    regionContainer.addSubView @regionSelector = new KDSelectBox
      name          : "region"
      selectOptions : [
        { title: "United States (North Virginia)", value: "us-east-1" }
        { title: "United States (Oregon)",         value: "us-west-2" }
        { title: "Singapore",                      value: "ap-southeast-1" }
        { title: "Ireland",                        value: "eu-west-1" }
      ]

    regionContainer.addSubView @regionTextView = new KDView

    content.addSubView @snapshotsContainer = new KDView
      cssClass : 'snapshots-container hidden'

    @snapshotsContainer.addSubView new KDView
      cssClass : 'container-title'
      partial  : 'build from snapshot'

    @snapshotsContainer.addSubView @snapshotsSelector = new KDSelectBox
      name          : 'snapshots'
      selectOptions : [ title: 'None', value: "" ]
      callback      : =>
        # Update the usage text with the value of the slider
        #
        # Note that @getValues() just returns the value *option* of the
        # handles, so we're getting the value directly.
        @updateSnapshotUsageText @storageSlider.handles.first.value
        @updateCreateVMBtnEnabled @storageSlider.handles.first.value

    content.addSubView storageContainer = new KDView
      cssClass : "storage-container"

    storageContainer.addSubView new KDView
      cssClass : "container-title"
      partial  : "allocate storage for your new vm"

    storageContainer.addSubView @storageSlider = new CustomPlanStorageSlider
      cssClass : 'storage-slider'
      maxValue : limits.storage # limits.storage - usage.storage
      minValue : 3
      handles  : [5]

    storageContainer.addSubView @usageTextView         = new KDView
    storageContainer.addSubView @snapshotUsageTextView = new KDView
      cssClass : 'warn hidden'

    content.addSubView @createVMButton = new KDButtonView
      title    : "Create your VM"
      style    : 'solid medium green'
      loader   : yes
      callback : @bound "createVM"
      disabled : usage.total >= limits.total

    unless plan in ['professional', 'super']
      content.addSubView new CustomLinkView
        title : 'Upgrade your account for more VMs RAM and Storage'
        href  : '/Pricing'
        click : ->
          trackEvent 'Upgrade your account, click',
            category : 'userInteraction'
            action   : 'clicks'
            label    : 'upgradeAccountOverlay'
            origin   : 'paidModal'

    @populateSnapshotsSelector()

    @updateStorageUsageText 5, usage, limits
    @updateSnapshotUsageText 5
    @updateCreateVMBtnEnabled 5
    @storageSlider.on "ValueIsChanging", (val)=>
      @updateStorageUsageText val, usage, limits
      @updateSnapshotUsageText val
      @updateCreateVMBtnEnabled val

    @updateRegionText()
    @regionSelector.on "change", @bound 'updateRegionText'

    @setPositions()


  ###*
   * Fetch the jSnapshots and populate the snapshotsSelector with any
   * snapshots the user has. If none are available, the selector is
   * left hidden.
  ###
  populateSnapshotsSelector: ->

    { JSnapshot }     = remote.api
    defaultSnapshotId = @getOptions().snapshotId

    # A cache of loaded snapshots, by snapshotId
    @snapshots = {}

    JSnapshot.some {}, {}, (err, snapshots) =>
      return kd.warn err  if err
      # If no snapshots were returned, the user has no snapshots, and
      # no action is needed
      return  if not snapshots? or snapshots.length is 0
      formatted = []
      for snapshot in snapshots
        { snapshotId }         = snapshot
        @snapshots[snapshotId] = snapshot
        formatted.push
          title: "#{snapshot.label} (#{snapshot.storageSize}GB)"
          value: snapshotId

      @snapshotsSelector.setSelectOptions formatted
      # Set the selected option to the Modal's option.snapshotId,
      # defaulting to the None item ("" value)
      @snapshotsSelector.setValue defaultSnapshotId ? ""
      @snapshotsContainer.show()

      # Update the usage text with the value of the slider
      #
      # Note that @getValues() just returns the value *option* of the
      # handles, so we're getting the value directly.
      @updateSnapshotUsageText @storageSlider.handles.first.value
      @updateCreateVMBtnEnabled @storageSlider.handles.first.value


  updateRegionText: ->

    region = @regionSelector.getValue()

    @regionTextView.updatePartial "Current region is <strong>#{region}</strong>"



  ###*
   *
   * @param {Number} sliderValue
  ###
  updateCreateVMBtnEnabled: (sliderValue) ->

    { usage, limits } = @getOptions()

    # The user can't create anymore VMs
    return @createVMButton.disable()  if usage.total >= limits.total

    newUsage = usage.storage + sliderValue

    # The user is trying to create a VM bigger than they have resources
    # for
    return @createVMButton.disable()  if newUsage > limits.storage

    snapshotId = @snapshotsSelector.getValue()
    if snapshotId
      snapshot = @snapshots[snapshotId]
      # The user is trying to create a VM from a snapshot, bigger
      # than the sliderValue's storage
      return @createVMButton.disable()  if sliderValue < snapshot.storageSize

    # Finally, no checks have failed. Show the create button.
    @createVMButton.enable()


  ###*
   * Update the snapshot usage text.
   *
   * @param {Number} sliderValue
  ###
  updateSnapshotUsageText: (sliderValue) ->

    snapshotId = @snapshotsSelector.getValue()

    unless snapshotId
      return @snapshotUsageTextView.hide()

    snapshot = @snapshots[snapshotId]

    if sliderValue < snapshot.storageSize
      @snapshotUsageTextView.show()
      @snapshotUsageTextView.updatePartial """
          Snapshot '#{snapshot.label}' requires <strong>
          #{snapshot.storageSize}GB</strong> of storage
      """
    else
      @snapshotUsageTextView.hide()


  updateStorageUsageText: (val, usage, limits)->

    newUsage = usage.storage + val

    if newUsage > limits.storage
    then @usageTextView.setClass 'warn'
    else @usageTextView.unsetClass 'warn'

    @usageTextView.updatePartial """
      You will be using <strong>#{newUsage}GB/#{limits.storage}GB</strong> storage
    """

  createVM:->

    { computeController } = kd.singletons

    stack      = computeController.stacks.first._id
    storage    = @storageSlider.handles.first.value
    region     = @regionSelector.getValue()
    snapshotId = @snapshotsSelector.getValue() ? null

    computeController.create {
      provider : "koding", stack, storage, region, snapshotId
    }, (err, machine)=>

      return  if showError err

      @createVMButton.hideLoader()
      @destroy()
