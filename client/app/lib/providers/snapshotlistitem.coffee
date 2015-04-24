Encoder             = require 'htmlencode'

kd                  = require 'kd'
remote              = require('app/remote').getInstance()
{JSnapshot}         = remote.api

JView               = require '../jview'
nicetime            = require '../util/nicetime'



module.exports = class SnapshotListItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'snapshot'

    super options, data

    @initViews()
    @setLabel data.label


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = "") ->

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
      cssClass : 'solid green compact rename'
      callback : @bound 'renameSnapshot'

    @editCancelBtn = new kd.View
      partial  : 'cancel'
      tagName  : 'span'
      tagName  : 'span'
      cssClass : 'cancel'
      click    : @bound 'toggleEditable'

    @labelView = new kd.View
      tagName  : 'span'
      cssClass : 'label'
      click    : @bound 'toggleEditable'

    @infoRenameBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'rename'
      callback : @bound 'toggleEditable'

    @infoDeleteBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'delete'
      callback : @bound "confirmDeleteSnapshot"

    @addSubView @editView = new JView
      cssClass: 'edit hidden'
      pistachioParams: {@editInput, @editRenameBtn, @editCancelBtn}
      pistachio: """
        <div>
          {{> editInput}}
          <div class="buttons">
            {{> editRenameBtn}}
            {{> editCancelBtn}}
          </div>
        </div>
        """

    @addSubView @infoView = new JView
      cssClass: 'info'
      pistachioParams: {@labelView, @infoRenameBtn, @infoDeleteBtn}
      pistachio: """
        <div>
          {{> labelView}}
          <span class="storage-size">(#{data.storageSize}GB)</span>
          <span class="created-at">
            #{SnapshotListItem.prettyCreatedAt data.createdAt}
          </span>
          <div class="buttons">
            {{> infoRenameBtn}}
            {{> infoDeleteBtn}}
          </div>
        </div>
        """


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
        @getDelegate().removeItem this
      .catch (err) -> kd.warn err


  partial: ->


  ###*
   * Get the name input value, and emit the RenameSnapshot event with
   * the proper data
  ###
  renameSnapshot: ->

    label        = @editInput.getValue()
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

    if @infoView.$().is ":visible"
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editInput.bound "setFocus"
    else
      @infoView.show()
      @editView.hide()

