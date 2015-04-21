Encoder                   = require 'htmlencode'

kd                        = require 'kd'
remote                    = require('app/remote').getInstance()
{JSnapshot}               = remote.api

MachineSettingsCommonView = require './machinesettingscommonview'
SnapshotsListController   = require './snapshotslistcontroller'
SnapshotListItem          = require './snapshotlistitem'



module.exports = class MachineSettingsSnapshotsView extends MachineSettingsCommonView

  constructor:(options = {}, data) ->

    options.cssClass             = "snapshots #{options.cssClass}"
    options.headerTitle          = 'Snapshots'
    options.addButtonTitle       = 'ADD SNAPSHOT'
    options.headerAddButtonTitle = 'ADD NEW SNAPSHOT'
    options.listViewItemClass    = SnapshotListItem

    super options, data


  helper =
    ###*
     * Fetch the list of snapshots from DB
     *
     * @param {Function(err:Error, snapshots:[JSnapshot]} callback
    ###
    fetchSnapshots: (callback=kd.noop) ->

      JSnapshot.some {}, {}, (err, snapshots) =>
        if err?
          return callback err
        callback err, snapshots
      return


  ###*
   * Create a new snapshot with the given name, from the given machineId
   *
   * @param {String} label - The label (name) of the snapshot
   * @param {Function(err:Error, snapshot:JSnapshot)} callback
  ###
  createSnapshot: (label, callback=kd.noop) ->

    computeController = kd.getSingleton 'computeController'
    machine           = @getData()
    machineId         = machine._id
    eventId           = "createSnapshot-#{machineId}"
    # Because kloud.createSnapshot does not return a snapshot object,
    # we need to request the newest snapshot (sorted by creation date)
    #
    # TODO: Confirm that this is the proper way to achieve this
    # result.
    findJustCreatedSnapshot = ->
      JSnapshot.some {machineId}, {sort: {createdAt: -1}, limit: 1},
        (err, [snapshot]) =>
          if err?
            return callback err
          if not snapshot?
            return callback new Error "SnapshotListController.createSnapshot: Cannot find most recent snapshot"
          callback null, snapshot

    monitorProgress = => computeController.on eventId, ({percentage}) =>
      findJustCreatedSnapshot() if percentage >= 100
      @emit "SnapshotProgress", percentage

    # TODO: Handle the case where a VM is not built.
    computeController.createSnapshot machine, label
      .then monitorProgress
      .catch callback
    return


  ###*
   * Called when the Add New button is clicked (the one to actually
   * confirm the submission, not show the new snapshot input form)
  ###
  # TODO: Test the in progress stuff (show a ui if the user tries to press
  # again, etc
  handleAddNew: ->

    machineId = @getData()._id
    label = @addInputView.getValue()
    if not label? or label is ""
      @notify "Name length must be larger than zero"
      return

    # Explicitly showing the loader because the hitEnterTextView does
    # not trigger the button loader when entered.
    @addNewButton.showLoader()
    @isInProgress = yes
    @createSnapshot label, (err, snapshot) =>
      @hideAddView()
      @isInProgress = no
      @addInputView.setValue ''
      @addNewButton.hideLoader()
      if err?
        kd.warn "MachineSettingsSnapshotsView.handleAddNew:", err
        @notify "An error was encountered creating the Snapshot"
        return
      @listController.addItem snapshot
    return


  ###*
   * Populate the listController with snapshots fetched from jSnapshot.
  ###
  initList: ->

    MachineSettingsSnapshotsView.helper.fetchSnapshots (err, snapshots=[]) =>
      kd.warn "MachineSettingsSnapshotsView.initList
        Error:", err if err?
      @listController.lazyLoader.hide()
      @listController.replaceAllItems snapshots


  # A standard way to communicate to the user.
  # TODO: Use the proper feedback UI (whatever that may be)
  notify: (msg="") ->

    new kd.NotificationView content: msg
    return


