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
      selectOptions : [ title: 'None', value: null ]

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

    storageContainer.addSubView @usageTextView = new KDView

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

    @updateUsageText 5, usage, limits
    @storageSlider.on "ValueIsChanging", (val)=>
      @updateUsageText val, usage, limits

    @updateRegionText()
    @regionSelector.on "change", @bound 'updateRegionText'

    @populateSnapshotsSelector()

    @setPositions()


  ###*
   * Fetch the jSnapshots and populate the snapshotsSelector with any
   * snapshots the user has. If none are available, the selector is
   * left hidden.
  ###
  populateSnapshotsSelector: ->

    { snapshotId } = @getOptions()
    { JSnapshot }  = remote.api

    JSnapshot.some {}, {}, (err, snapshots) =>
      return kd.warn err  if err
      # If no snapshots were returned, the user has no snapshots, and
      # no action is needed
      return  if not snapshots? or snapshots.length is 0
      formatted = []
      for snapshot in snapshots
        formatted.push
          title: "#{snapshot.label} (#{snapshot.storageSize}GB)"
          value: snapshot.snapshotId

      @snapshotsSelector.setSelectOptions formatted
      # Set the selected option to the Modal's option.snapshotId,
      # defaulting to the None item (null value)
      @snapshotsSelector.setValue snapshotId ? null
      @snapshotsContainer.show()


  updateRegionText: ->

    region = @regionSelector.getValue()

    @regionTextView.updatePartial "Current region is <strong>#{region}</strong>"

  updateUsageText: (val, usage, limits)->

    newUsage = usage.storage + val

    if newUsage > limits.storage
      @usageTextView.setClass 'warn'
      @createVMButton.disable()
    else
      @usageTextView.unsetClass 'warn'
      @createVMButton.enable()  unless usage.total >= limits.total

    @usageTextView.updatePartial """
      You will be using <strong>#{newUsage}GB/#{limits.storage}GB</strong> storage
    """

  createVM:->

    { computeController } = kd.singletons

    stack = computeController.stacks.first._id
    storage = @storageSlider.handles.first.value
    region = @regionSelector.getValue()
    snapshotId = @snapshotsSelector.getValue()

    computeController.create {
      provider : "koding", stack, storage, region, snapshotId
    }, (err, machine)=>

      return  if showError err

      @createVMButton.hideLoader()
      @destroy()
