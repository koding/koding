kd                        = require 'kd'
remote                    = require('app/remote').getInstance()
Encoder                   = require 'htmlencode'
SnapshotListItem          = require './snapshotlistitem'
snapshotHelpers           = require './snapshothelpers'
ComputeErrorUsageModal    = require './computeerrorusagemodal'
MachineSettingsCommonView = require './machinesettingscommonview'
getIdeByMachine           = require '../util/getIdeByMachine'


module.exports = class MachineSettingsSnapshotsView extends MachineSettingsCommonView

  constructor: (options = {}, data) ->

    options.cssClass             = kd.utils.curry options.cssClass, 'snapshots'
    options.headerTitle          = 'Snapshots'
    options.addButtonTitle       = 'ADD SNAPSHOT'
    options.headerAddButtonTitle = 'ADD NEW SNAPSHOT'
    options.listViewItemClass    = SnapshotListItem
    options.noItemFoundWidget    = new kd.CustomHTMLView
      cssClass : 'no-item'
      partial  : 'You do not have any snapshots created'

    # Trigger the snapshotsLimits fetch, so that we can cache it ahead of time.
    @snapshotsLimit()

    super options, data

    @listController.getListView().on 'DeleteSnapshot', =>
      @listController.showNoItemWidget()


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = '') ->

    new kd.NotificationView content: msg


  ###*
   * The various snapshot total limits.
  ###
  @snapshotsLimits:
    default      : 5
    free         : 0
    hobbyist     : 1
    developer    : 3
    professional : 5


  ###*
   * Create a new snapshot with the given name, from the given machineId
   *
   * @param {String} label - The label (name) of the snapshot
   * @param {Function(err:Error, snapshot:JSnapshot)} callback
  ###
  createSnapshot: (label, callback = kd.noop) ->

    computeController = kd.getSingleton 'computeController'
    machine           = @getData()
    machineId         = machine._id
    eventId           = "createSnapshot-#{machineId}"

    monitorProgress = (event) =>
      {error, percentage} = event
      @emit 'SnapshotProgress', percentage
      return  if percentage < 100
      # Remove the subscriber if the percent is >= 100
      computeController.off eventId, monitorProgress
      return callback error  if error
      # Because kloud.createSnapshot does not return a snapshot object,
      # we need to request the newest snapshot (sorted by creation date)
      snapshotHelpers.fetchNewestSnapshot machineId, callback

    computeController.createSnapshot machine, label
      .catch callback
      .then -> computeController.on eventId, monitorProgress


  ###*
   * Create the add new snapshot buttons. Overloading
   * MachineSettingsCommonView's method to swap the button order.
  ###
  createAddNewViewButtons: ->
    wrapper = new kd.CustomHTMLView cssClass: 'buttons'

    wrapper.addSubView new kd.CustomHTMLView
      tagName  : 'span'
      partial  : 'cancel'
      cssClass : 'cancel'
      click    : @bound 'hideAddView'

    wrapper.addSubView @addNewButton = new kd.ButtonView
      cssClass : 'solid green compact add'
      loader   : yes
      title    : @getOptions().addButtonTitle
      callback : @bound 'handleAddNew'

    @addViewContainer.addSubView wrapper


  ###*
   * Called when the Add New button is clicked (the one to actually
   * confirm the submission, not show the new snapshot input form)
  ###
  handleAddNew: ->

    machine   = @getData()
    machineId = machine._id
    label     = @addInputView.getValue()
    if not label? or label is ''
      return MachineSettingsSnapshotsView.notify \
        'Name length must be larger than zero'

    # Get the IDE view.
    ideController = getIdeByMachine machine
    container     = ideController?.getView()

    unless container?
      router = kd.getSingleton 'router'
      router.handleRoute "/IDE/#{machine.slug}"
      msg = "Error, unable to create snapshot. Please try again."
      @showNotification msg, 'error'
      return kd.error "Unable to create snapshot, IDE Could not be found"

    @emit 'ModalDestroyRequested'
    modal = snapshotHelpers.showSnapshottingModal machine, container

    @on 'SnapshotProgress', modal.bound 'updatePercentage'
    @createSnapshot label, (err, snapshot) =>
      @off 'SnapshotProgress', modal.bound 'updatePercentage'
      if err
        kd.warn err
        return modal.showError()

      modal.destroy()
      # Importing this here, because the order of imports means that
      # MachineSettingsSnapshotsView gets created before MachineSettingsModal.
      # Ie, we can't import it at the beginning of this file.
      MachineSettingsModal = require './machinesettingsmodal'
      settingsModal        = new MachineSettingsModal {}, machine
      settingsModal.tabView.showPaneByName 'Snapshots'


  ###*
   * Triggered when the header add new snapshot is pressed.
  ###
  hideAddView: ->

    super

    @listController.showNoItemWidget()


  ###*
   * Populate the listController with snapshots fetched from jSnapshot.
  ###
  initList: ->

    {JSnapshot} = remote.api
    JSnapshot.some {}, {}, (err, snapshots = []) =>
      kd.warn err  if err
      @listController.lazyLoader.hide()
      @listController.replaceAllItems snapshots


  ###*
   * Fetch the snapshot total and in use snapshots to calculate if the
   * user is within the snapshot limit.
   *
   * Note that to save on db calls, this UI just counts the number of
   * list items as snapshots.
   *
   * @param {Function(err:Error, isWithin:Bool)} callback
  ###
  isWithinSnapshotLimit: (callback = kd.noop) ->
    @snapshotsLimit (err, total) =>
      return callback err  if err
      count = @listController.getItemCount()
      callback null, count < total, count, total


  ###*
   * Called when the headerAddNewButton click event fires.
  ###
  showAddView: ->

    @isWithinSnapshotLimit (err, isWithin, current, max) =>
      kd.warn err  if err

      # If the max is 0, the user has no allotted snapshots (free plan)
      if max is 0
        new ComputeErrorUsageModal
          plan    : 'free'
          message : 'The Snapshot feature is only available for paid accounts.'

        return @emit 'ModalDestroyRequested'

      if not isWithin
        msg = "Your current plan allows for a maximum of #{max} Snapshots"
        @showNotification msg, 'error'
        @addNewButton.hideLoader()

        return

      @listController.hideNoItemWidget()

      @headerAddNewButton.hide()
      @addViewContainer.show()
      kd.utils.defer @addInputView.bound 'setFocus'


  ###*
   * Fetch and cache the user's total snapshot limit.
   *
   * If the user's planTitle is unrecognized, clientside will default to
   * `snapshotsLimits['default']`, and log a warning.
   *
   * @param {Function(err:Error, totalLimit:Number)} callback
  ###
  snapshotsLimit: (callback = kd.noop) ->
    return callback null, @__snapshotsLimit  if @__snapshotsLimit?

    paymentController = kd.getSingleton 'paymentController'
    paymentController.subscriptions (err, subscription) =>
      return callback err  if err

      snapshotsLimits = MachineSettingsSnapshotsView.snapshotsLimits
      {planTitle} = subscription
      @__snapshotsLimit = snapshotsLimits[planTitle]
      if not @__snapshotsLimit?
        kd.warn "snapshotsLimit check: Plan title '#{planTitle}'
          unrecognized, using default."
        @__snapshotsLimit =  snapshotsLimits['default']
      callback null, @__snapshotsLimit


