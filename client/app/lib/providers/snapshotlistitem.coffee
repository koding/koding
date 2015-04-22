Encoder             = require 'htmlencode'

kd                  = require 'kd'
remote              = require('app/remote').getInstance()
{JSnapshot}         = remote.api

nicetime            = require '../util/nicetime'



module.exports = class SnapshotListItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'snapshot'

    super options, data

    @initViews()
    @setLabel data.label
    @setCreatedAt data.createdAt
    @setStorageSize data.storageSize


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = "") ->

    new kd.NotificationView content: msg
    return


  ###*
   * Create all of the subviews.
  ###
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
  ###
  deleteSnapshot: ->

    computeController       = kd.getSingleton 'computeController'
    kloud                   = computeController.getKloud()
    {machineId, snapshotId} = @getData()

    kloud.deleteSnapshot {machineId, snapshotId}
      .then =>
        @getDelegate().emit 'DeleteSnapshot', this
        @destroy()
      .catch (err) -> kd.warn err
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
      SnapshotListItem.notify "Name length must be larger than zero"
      return

    # Called once we have a jSnapshot to work with
    rename = (snapshot) => snapshot.rename label, (err) =>
      return kd.warn err  if err
      @toggleEditable()
      @setLabel label
      @getDelegate().emit "RenameSnapshot", this, label

    # If data is a jsnapshot, we don't need to fetch it
    if data instanceof JSnapshot
      rename data
    else
      JSnapshot.one snapshotId, (err, snapshot) =>
        return kd.warn err  if err

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


  ###*
   * Toggle (swap) the visibility of @infoView and @editView
  ###
  toggleEditable: ->

    if @infoView.$().is ":visible"
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editView.edit.bound "setFocus"
    else
      @infoView.show()
      @editView.hide()

