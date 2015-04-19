kd                      = require 'kd'
Encoder                 = require 'htmlencode'
remote                  = require('app/remote').getInstance()
{computeController}     = kd.singletons
{JSnapshot}             = remote.api
SnapshotsListController = require './snapshotslistcontroller'


module.exports = class MachineSettingsSnapshotsView extends kd.View

  constructor:(options = {}, data) ->
    options.cssClass = "snapshots #{options.cssClass}"
    super options, data

    @machineId = machineId = data?._id
    if not machineId?
      console.warn 'MachineSettingsSnapshotsView: Failed to find machineId'
      return
    @snapshotsController = new SnapshotsListController {}, machineId: machineId
    @initViews()

  initViews: ->
    @header = new kd.HeaderView
      title: "Snapshots"

    # Create an empty snapshot ui, which will be responsible for adding
    # the new snapshot.
    @showNewSnapshotBtn = new kd.ButtonView
      title: "Add Snapshot"
      style: "solid green compact add-button"
      callback: @bound "showNewSnapshot"

    # The new snapshot input form
    @newSnapshotView = new kd.View
      cssClass: 'hidden'
    @newSnapshotView.addSubView @newSnapshotView.label = new kd.InputView
      placeholder: 'Snapshot Name'
      style: 'kdinput text Formline--half'
    @newSnapshotView.addSubView @newSnapshotView.save = new kd.ButtonView
      title: 'Add Snapshot'
      style: 'solid green compact'
      callback: @bound 'createNewSnapshot'
    @newSnapshotView.addSubView @newSnapshotView.cancel = new kd.ButtonView
      title: "Cancel"
      style: "cancel"
      callback: @bound "hideNewSnapshot"

    @loaderView = new kd.LoaderView
      showLoader: false
      loaderOptions:
        shape: 'spiral'

    # Add the views
    @addSubView @header
    @header.addSubView @showNewSnapshotBtn
    @addSubView @newSnapshotView
    @addSubView @loaderView
    @addSubView @snapshotsController.getView()

    @snapshotsController.instantiateSnapshotItems()
    return

  # Create a new snapshot from the machineId on this view, and the name
  # in the input. This will error check for the validity of the name.
  createNewSnapshot: ->
    machineId = @machineId
    label = @newSnapshotView.label.getValue()
    if not label? or label is ""
      @notify "Name length must be larger than zero"
      return

    @snapshotsController.createSnapshot machineId, label, (err, snapshot) =>
      if err?
        console.warn "MachineSettingsSnapshotsView.createSnapshot:", err
        @notify "An error was encountered creating the Snapshot"
        return
      console.log "machinesettingssnapshotsview.createSnapshot: Done!"
      @snapshotsController.addSnapshotItem snapshot
      @hideNewSnapshot()
      @loaderView.hide()

    # Hide the new snapshot view, and create a throbber to show loading
    # NOTE: This will likely take UX refinement/tweaking (a throbber isn't
    # exactly the best UX for more than a few seconds)
    @newSnapshotView.hide()
    @loaderView.show()

    return

  # Hide the new snapshot input, and show the showNewSnapshotBtn
  hideNewSnapshot: ->
    @newSnapshotView.hide()
    @showNewSnapshotBtn.show()

  # A standard way to communicate to the user.
  # TODO: Use the proper feedback UI (whatever that may be)
  notify: (msg="") ->
    new kd.NotificationView content: msg
    return

  # Show the new snapshot input and hide the showNewSnapshotBtn
  showNewSnapshot: ->
    @newSnapshotView.show()
    @showNewSnapshotBtn.hide()
    kd.utils.defer @newSnapshotView.label.bound "setFocus"

