kd                  = require 'kd'
Encoder             = require 'htmlencode'
remote              = require('app/remote').getInstance()
{computeController} = kd.singletons
{JSnapshot}         = remote.api
SnapshotListItem    = require './snapshotlistitem'


module.exports = class SnapshotsListController extends kd.ListViewController

  constructor: (options={}, data) ->
    listView = options.view ?= new kd.ListView
      itemClass: SnapshotListItem
    super options, data

    listView.on "RenameSnapshot", (item, label) =>
      snapshotData = item.getData()
      @renameSnapshot snapshotData.snapshotId, label,
        (err) =>
          item.toggleEditable()
          if err? then return
          item.setLabel label

    listView.on "DeleteSnapshot", (item) =>
      snapshotData = item.getData()
      @deleteSnapshot snapshotData.machineId, snapshotData.snapshotId,
        (err) => if not err? then item.destroy()


  # Is the current user allowed to have more snapshots?
  hasCreatePerms: (callback=kd.noop) ->
    callback true
    return

  addSnapshotItem: (snapshot, index=0) ->
    @addItem snapshot, index
    return

  # Fetch the snapshots from db
  fetchSnapshots: (callback=kd.noop) ->
    JSnapshot.some {}, {}, callback
    return

  # Add the snapshot items to the listview
  instantiateSnapshotItems: (callback=kd.noop) ->
    @fetchSnapshots (err, snapshots) =>
      if err?
        console.warn "SnapshotListController.instantiateSnapshotViews Error:", err
        return callback err

      @instantiateListItems snapshots
      callback()
    return

  # Create a new snapshot with the given name, from the given machineId
  #
  # callback(err, snapshot)
  createSnapshot: (machineId, label, callback=kd.noop) ->
    machine = computeController.machinesById[machineId]
    eventId = "createSnapshot-#{machineId}"
    # Because kloud.createSnapshot does not return a snapshot object,
    # we need to request the newest snapshot (sorted by creation date)
    #
    # Why do we want it? Well, the caller of this method (likely a
    # listItem) needs to populate itself with the data of this newly
    # created snapshot. Mostly the snapshotId.
    #
    # TODO: Confirm that this is the proper way to achieve this
    # result.
    findJustCreatedSnapshot = ->
      JSnapshot.some {machineId: machineId},
        {sort: {createdAt: -1}, limit: 1},
        (err, [snapshot]) =>
          if err?
            return callback err
          if not snapshot?
            return callback new Error "SnapshotListController.createSnapshot: Cannot find most recent snapshot"
          callback null, snapshot

    monitorProgress = => computeController.on eventId, ({percentage}) =>
      findJustCreatedSnapshot() if percentage >= 100
      @emit "SnapshotProgress", percentage

    #kloud.createSnapshot machineId: machineId
    #  .then findJustCreatedSnapshot
    #  .catch callback
    console.log "Calling computeController createSnapshot(#{machineId},#{label})"
    computeController.createSnapshot machine, label
      .then monitorProgress
      .catch callback
    return

  # Delete the given snapshot.
  deleteSnapshot: (machineId, snapshotId, callback=kd.noop) ->
    kloud = computeController.getKloud()
    kloud.deleteSnapshot machineId: machineId, snapshotId: snapshotId
      .then -> callback null
      .catch (err) ->
        console.warn "SnapshotListController.deleteSnapshot Error:", err
        callback()
    return

  # A standard way to communicate to the user.
  # TODO: Use the proper feedback UI (whatever that may be)
  notify: (msg="") ->
    new kd.NotificationView content: msg
    return

  # Rename the given shapshot
  renameSnapshot: (snapshotId, label, callback=kd.noop) ->
    JSnapshot.one snapshotId,
      (err, snapshot) =>
        if err?
          console.warn "SnapshotListController.renameSnapshot Error:", err
          return callback err

        if not snapshot?
          console.warn "SnapshotListController.renameSnapshot Error: Cannot find snapshotId", snapshotId
          return callback err

        snapshot.rename label, (err) =>
          if err?
            console.warn "SnapshotListController.renameSnapshot:", err
            return callback err
          callback()
    return

  # Create a VM from the given snapshotId
  vmFromSnapshot: (snapshotId, callback=kd.noop) ->
    @notify "Not implemented"
    callback()
    return
