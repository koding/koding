Encoder                   = require 'htmlencode'

kd                        = require 'kd'
remote                    = require('app/remote').getInstance()

MachineSettingsCommonView = require './machinesettingscommonview'
SnapshotListItem          = require './snapshotlistitem'
snapshotHelpers           = require './snapshothelpers'



module.exports = class MachineSettingsSnapshotsView extends MachineSettingsCommonView

  constructor:(options = {}, data) ->

    options.cssClass             = kd.utils.curry options.cssClass, 'snapshots'
    options.headerTitle          = 'Snapshots'
    options.addButtonTitle       = 'ADD SNAPSHOT'
    options.headerAddButtonTitle = 'ADD NEW SNAPSHOT'
    options.listViewItemClass    = SnapshotListItem

    # Trigger the snapshotsLimits fetch, so that we can cache it ahead
    # of time.
    @snapshotsLimit()

    super options, data


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = '') ->

    new kd.NotificationView content: msg


  ###*
   * The various snapshot total limits.
  ###
  @snapshotsLimits:
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
   * Called when the Add New button is clicked (the one to actually
   * confirm the submission, not show the new snapshot input form)
  ###
  handleAddNew: ->

    machineId = @getData()._id
    label = @addInputView.getValue()
    if not label? or label is ''
      return MachineSettingsSnapshotsView.notify \
        'Name length must be larger than zero'

    # Explicitly showing the loader because the hitEnterTextView does
    # not trigger the button loader when entered.
    @addNewButton.showLoader()
    @createSnapshot label, (err, snapshot) =>
      @hideAddView()
      @addInputView.setValue ''
      @addNewButton.hideLoader()
      return kd.warn err  if err
      @listController.addItem snapshot


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
      if not isWithin
        msg = "Your current plan allows for a maximum of #{max} Snapshots"
        @showNotification msg, 'error'
        @addNewButton.hideLoader()
        return

      @headerAddNewButton.hide()
      @addViewContainer.show()
      kd.utils.defer @addInputView.bound 'setFocus'


  ###*
   * Fetch and cache the user's total snapshot limit.
   *
   * @param {Function(err:Error, totalLimit:Number)} callback
  ###
  snapshotsLimit: (callback = kd.noop) ->
    return callback null, @__snapshotsLimit  if @__snapshotsLimit?

    paymentController = kd.getSingleton 'paymentController'
    paymentController.subscriptions (err, subscription) =>
      return callback err  if err

      {planTitle} = subscription
      @__snapshotsLimit = MachineSettingsSnapshotsView.snapshotsLimits[planTitle]
      callback null, @__snapshotsLimit


