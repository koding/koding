Encoder                   = require 'htmlencode'

kd                        = require 'kd'
remote                    = require('app/remote').getInstance()

{handleNewMachineRequest} = require './computehelpers'
JView                     = require '../jview'
nicetime                  = require '../util/nicetime'



module.exports = class SnapshotListItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.type = 'snapshot'

    options.cssClass = kd.utils.curry options.cssClass, 'snapshot'

    super options, data

    @initViews()
    @setLabel data.label


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = '') ->

    new kd.NotificationView content: msg


  ###*
   * Return a nicely formatted created at.
  ###
  @prettyCreatedAt: (createdAt) ->

    createdAt = new Date(createdAt) if typeof createdAt is 'string'
    createdAtAgo = nicetime (createdAt - Date.now()) / 1000

    return createdAtAgo


  ###*
   * Create all of the subviews.
  ###
  initViews: ->

    data = @getData()
    @editInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Snapshot Name'
      cssClass    : 'label'
      callback    : @bound 'renameSnapshot'

    @editRenameBtn = new kd.ButtonView
      title    : 'rename'
      cssClass : 'solid green small rename'
      callback : @bound 'renameSnapshot'

    @editCancelBtn = new kd.View
      partial  : 'cancel'
      tagName  : 'span'
      tagName  : 'span'
      cssClass : 'cancel'
      click    : @bound 'toggleEditable'

    @labelView = new kd.View
      tagName  : 'span'
      cssClass : 'label column'
      click    : @bound 'toggleEditable'

    @infoRenameBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'rename'
      callback : @bound 'toggleEditable'
      tooltip  :
        title  : 'Rename Snapshot'

    @infoDeleteBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'delete'
      callback : @bound 'confirmDeleteSnapshot'
      tooltip  :
        title  : 'Delete Snapshot'

    @infoNewVmBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'new-vm'
      callback : @bound 'vmFromSnapshot'
      tooltip  :
        title  : 'Create VM from Snapshot'

    @addSubView @editView = new JView
      cssClass        : 'edit hidden'
      pistachioParams : { @editInput, @editRenameBtn, @editCancelBtn }
      pistachio       : """
        {{> editInput}}
        <div class="buttons">
          {{> editCancelBtn}}
          {{> editRenameBtn}}
        </div>
        """

    @addSubView @infoView = new JView
      cssClass        : 'info'
      pistachioParams : { @labelView, @infoRenameBtn, @infoDeleteBtn,
        @infoNewVmBtn }
      pistachio       : """
        {{> labelView}}
        <span class="column created-at">#{SnapshotListItem.prettyCreatedAt data.createdAt}</span>
        <span class="column size">#{data.storageSize}GB</span>
        <div class="buttons">
          {{> infoRenameBtn}}
          {{> infoDeleteBtn}}
          {{> infoNewVmBtn}}
        </div>
        """


  ###*
   * Show the UI confirmation for snapshot delete, and delete the
   * snapshot if Yes is chosen.
  ###
  confirmDeleteSnapshot: ->

    modal = kd.ModalView.confirm
      title      : 'Delete snapshot?'
      ok         :
        title    : 'Yes'
        style    : 'solid red medium'
        callback : =>
          modal.destroy()
          @deleteSnapshot()
      cancel     :
        style    : 'solid light-grey medium'
        type     : 'button'
        callback : -> modal.destroy()


  ###*
   * Delete this snapshot, and destroy this View on success.
  ###
  deleteSnapshot: ->

    computeController       = kd.getSingleton 'computeController'
    kloud                   = computeController.getKloud()
    {machineId, snapshotId} = @getData()

    kloud.deleteSnapshot {machineId, snapshotId}
      .then =>
        listView = @getDelegate()
        listView.removeItem this
        listView.emit 'DeleteSnapshot', this
      .catch (err) -> kd.warn err


  ###*
   * Notify the delegate (listView) to create a vm from this item's
   * snapshot.
   *
   * @emits ListView~NewVmFromSnapshot
  ###
  vmFromSnapshot: ->

    listView = @getDelegate()
    listView.emit 'NewVmFromSnapshot', @getData()


  partial: ->


  ###*
   * Get the name input value, and emit the RenameSnapshot event with
   * the proper data
  ###
  renameSnapshot: ->

    {JSnapshot}  = remote.api
    label        = @editInput.getValue()
    data         = @getData()
    {snapshotId} = data

    if not label? or label is ''
      SnapshotListItem.notify 'Name length must be larger than zero'
      return

    # Called once we have a jSnapshot to work with
    rename = (snapshot) => snapshot.rename label, (err) =>
      return kd.warn err  if err
      @toggleEditable()
      @setLabel label
      listView = @getDelegate()
      listView.emit 'RenameSnapshot', this, label

    # If data is a jsnapshot, we don't need to fetch it
    if data instanceof JSnapshot
      rename data
    else
      JSnapshot.one snapshotId, (err, snapshot) =>
        return kd.warn err  if err

        unless snapshot?
          return kd.warn 'Error: Cannot find snapshotId', snapshotId

        rename snapshot


  ###*
   * Set the value of the label (name) UI element.
   *
   * @param {String} label - The label (name) to set.
  ###
  setLabel: (label) ->

    @labelView.updatePartial label
    @editInput.setValue label


  ###*
   * Toggle (swap) the visibility of @infoView and @editView
  ###
  toggleEditable: ->

    if not @infoView.hasClass 'hidden'
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editInput.bound 'setFocus'
    else
      @infoView.show()
      @editView.hide()

