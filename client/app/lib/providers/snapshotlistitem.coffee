kd                  = require 'kd'
nicetime            = require '../util/nicetime'
Encoder             = require 'htmlencode'
remote              = require('app/remote').getInstance()
{JSnapshot}         = remote.api



module.exports = class SnapshotListItem extends kd.ListItemView

  constructor: (options={}, data) ->
    options.cssClass = "snapshot #{options.cssClass}"
    super options, data
    @initViews()
    @setLabel data.label
    @setCreatedAt data.createdAt
    @setStorageSize data.storageSize


  initViews: ->

    data = @getData()
    @editView = new kd.View
      cssClass: 'edit hidden'

    @editView.addSubView @editView.edit = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Snapshot Name'
      cssClass    : 'label'
      callback    : @bound 'renameSnapshot'

    @editView.addSubView wrapper = new kd.CustomHTMLView
      cssClass: 'buttons'

    wrapper.addSubView @editView.renameBtn = new kd.ButtonView
      title    : 'rename'
      cssClass : 'solid green compact rename'
      callback : @bound 'renameSnapshot'

    wrapper.addSubView @editView.cancelBtn = new kd.View
      partial  : 'cancel'
      tagName  : 'span'
      tagName  : 'span'
      cssClass : 'cancel'
      click    : @bound 'toggleEditable'

    @infoView = new kd.View
      cssClass: 'info'

    @infoView.addSubView @infoView.labelView = new kd.View
      tagName  : 'span'
      cssClass : 'label'
      click    : @bound 'toggleEditable'

    @infoView.addSubView @infoView.storageSizeView = new kd.View
      tagName  : 'span'
      cssClass : 'storage-size'

    @infoView.addSubView @infoView.createdAtView = new kd.View
      tagName  : 'span'
      cssClass : 'created-at'

    @infoView.addSubView wrapper = new kd.CustomHTMLView
      cssClass: 'buttons'

    wrapper.addSubView @infoView.renameSnapshotBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'rename'
      callback : @bound 'toggleEditable'

    wrapper.addSubView @infoView.deleteSnapshotBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'delete'
      callback : @bound "confirmDeleteSnapshot"

    @addSubView @editView
    @addSubView @infoView

  ###*
   * Show the UI confirmation for snapshot delete, and delete the
   * snapshot if Yes is chosen.
  ###
  confirmDeleteSnapshot: ->
    modal = kd.ModalView.confirm
      title: "Delete snapshot?"
      ok:
        title: "Yes"
        style: "solid red medium"
        callback: =>
          modal.destroy()
          @deleteSnapshot()
      cancel:
        style: "solid light-grey medium"
        type: "button"
        callback: -> modal.destroy()

  ###*
   * Delete this snapshot, and destroy this View on success.
   *
   * @param {Function(err:Error)} callback
  ###
  deleteSnapshot: (callback=kd.noop) ->
    computeController       = kd.getSingleton 'computeController'
    kloud                   = computeController.getKloud()
    {machineId, snapshotId} = @getData()

    kloud.deleteSnapshot {machineId, snapshotId}
      .then =>
        callback null
        @getDelegate().emit 'DeleteSnapshot', @
        @destroy()
      .catch callback
    return


  # A standard way to communicate to the user.
  # TODO: Use the proper feedback UI (whatever that may be)
  notify: (msg="") ->
    new kd.NotificationView content: msg
    return


  partial: ->


  ###*
   * Get the name input value, and emit the RenameSnapshot event with
   * the proper data
  ###
  renameSnapshot: ->
    label        = @editView.edit.getValue()
    data         = @getData()
    {snapshotId} = data

    if not label? or label is ""
      @notify "Name length must be larger than zero"
      return

    rename = (snapshot) => snapshot.rename label, (err) =>
      if err?
        kd.warn "SnapshotListItem.renameSnapshot:", err
        return
      @toggleEditable()
      @setLabel label
      @getDelegate().emit "RenameSnapshot", @, label

    # If data is a jsnapshot, we don't need to fetch it
    if data instanceof JSnapshot
      rename data
    else
      JSnapshot.one snapshotId, (err, snapshot) =>
        if err?
          kd.warn "SnapshotListItem.renameSnapshot Error:", err
          return

        if not snapshot?
          kd.warn "SnapshotListItem.renameSnapshot Error:
            Cannot find snapshotId", snapshotId
          return

        rename snapshot
    return


  ###*
   * Set the value of the createdAt UI element
   *
   * @param {Date|String} createdAt - The value to display createdAt
  ###
  setCreatedAt: (createdAt) ->
    createdAt = new Date(createdAt) if typeof createdAt is 'string'
    createdAtAgo = nicetime (createdAt - Date.now()) / 1000
    @infoView.createdAtView.updatePartial createdAtAgo
    return


  ###*
   * Set the value of the label (name) UI element.
   *
   * @param {String} label - The label (name) to set.
  ###
  setLabel: (label) ->
    @infoView.labelView.updatePartial label
    @editView.edit.setValue label
    return


  ###*
   * Set the value of the Storage Size UI element
   *
   * @param {Number} storageSize
  ###
  setStorageSize: (storageSize) ->
    @infoView.storageSizeView.updatePartial "(#{storageSize}GB)"
    return

  toggleEditable: ->
    if @infoView.$().is ":visible"
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editView.edit.bound "setFocus"
    else
      @infoView.show()
      @editView.hide()

