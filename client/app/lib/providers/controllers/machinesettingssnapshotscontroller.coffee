kd                   = require 'kd'
remote               = require('app/remote').getInstance()
SnapshotListItem     = require '../snapshotlistitem'
KodingListController = require 'app/kodinglist/kodinglistcontroller'

module.exports = class MachineSettingsSnapshotsController extends KodingListController

  constructor: (options = {}, data) ->

    options.itemClass         = SnapshotListItem
    options.noItemFoundWidget = new kd.CustomHTMLView
      cssClass                : 'no-item'
      partial                 : 'You do not have any Snapshots.'
    options.model             = remote.api.JSnapshot

    super options, data


  bindEvents: ->

    listView = @getListView()

    listView.on 'ItemAction', ({ action, item, options }) =>
      switch action
        when 'RenameSnapshot'
          @renameSnapshot item
        when 'DeleteSnapshot'
          @confirmDeleteSnapshot item, options
        when 'VMFromSnapshot'
          @vmFromSnapshot item


  confirmDeleteSnapshot: (item, options = {}) ->

    listView       = @getListView()

    confirmOptions =
      title        : options.title
      description  : options.description
      callback     : ({status, modal}) =>
        return  unless status
        modal.destroy()
        @deleteSnapshot item

    listView.askForConfirm confirmOptions

  ###*
   * Delete this snapshot, and destroy this View on success.
  ###
  deleteSnapshot: (item) ->

    computeController         = kd.getSingleton 'computeController'
    kloud                     = computeController.getKloud()
    { machineId, snapshotId } = item.getData()

    kloud.deleteSnapshot { machineId, snapshotId }
      .then =>
        listView = @getListView()
        listView.removeItem item
        listView.emit 'DeleteSnapshot', item
      .catch (err) -> kd.warn err


  ###*
   * Notify the delegate (listView) to create a vm from this item's
   * snapshot.
   *
   * @emits ListView~NewVmFromSnapshot
  ###
  vmFromSnapshot: (item) ->

    listView = @getListView()
    listView.emit 'NewVmFromSnapshot', item.getData()


  renameSnapshot: (item) ->

    { JSnapshot }  = remote.api
    label          = item.editInput.getValue()
    data           = item.getData()
    { snapshotId } = data

    if not label? or label is ''
      SnapshotListItem.notify 'Name length must be larger than zero'
      return

    # Called once we have a jSnapshot to work with
    rename = (snapshot) => snapshot.rename label, (err) =>
      return kd.warn err  if err
      item.toggleEditable()
      item.setLabel label
      listView = @getListView()
      listView.emit 'RenameSnapshot', item, label

    # If data is a jsnapshot, we don't need to fetch it
    if data instanceof JSnapshot
      rename data
    else
      JSnapshot.one snapshotId, (err, snapshot) =>
        return kd.warn err  if err

        unless snapshot?
          return kd.warn 'Error: Cannot find snapshotId', snapshotId

        rename snapshot
