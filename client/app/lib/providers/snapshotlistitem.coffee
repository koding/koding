kd       = require 'kd'
nicetime = require '../util/nicetime'
Encoder  = require 'htmlencode'



module.exports = class SnapshotListItem extends kd.ListItemView
  constructor: (options={}, data) ->
    super options, data
    @initViews()
    @setLabel data.label
    @setCreatedAt data.createdAt
    @setStorageSize data.storageSize

  initViews: ->
    data = @getData()
    @infoView = new kd.View
    @editView = new kd.FormViewWithFields
      fields:
        name:
          placeholder: "Snapshot Name"
      buttons:
        save:
          title: "Save"
          style: "solid compact green"
          callback: @bound "renameSnapshot"
        cancel:
          title: "Cancel"
          style: "thin compact gray"
          callback: @bound "toggleEditable"
        delete:
          title: "Delete"
          style: "thin compact red"
          callback: @bound "deleteSnapshot"
    # `style: "hidden"` didn't work, so using hide() for now.
    @editView.hide()

    @nameView = new kd.View
    @createdAtView = new kd.View tagName: "span"

    # TODO: These need to be icon only, but i'm not sure how to assign
    # icons yet.
    @renameSnapshotBtn = new kd.ButtonView
      title: "Rename"
      callback: => @toggleEditable()

    @deleteSnapshotBtn = new kd.ButtonView
      title: "Delete"
      callback: @bound "deleteSnapshot"

    # I think this won't be available in the first pass, as per Arslan's
    # comment on PT
    #@shareSnapshotBtn = new kd.ButtonView
    #  title: "Share"
    #  callback: => @shareSnapshot()

    @infoView.addSubView @nameView
    @infoView.addSubView @createdAtView
    @infoView.addSubView @renameSnapshotBtn
    @infoView.addSubView @deleteSnapshotBtn
    @addSubView @editView
    @addSubView @infoView

  # Show the UI confirmation for snapshot delete, and emit the
  # DeleteSnapshot event.
  deleteSnapshot: ->
    modal = kd.ModalView.confirm
      title: "Delete snapshot?"
      ok:
        title: "Yes"
        style: "solid red medium"
        callback: =>
          modal.destroy()
          @getDelegate().emit "DeleteSnapshot", @
      cancel:
        style: "solid light-grey medium"
        type: "button"
        callback: -> modal.destroy()

  partial: ->

  # Get the name input value, and emit the RenameSnapshot event with
  # the proper data
  renameSnapshot: ->
    label = @editView.inputs.name.getValue()
    @getDelegate().emit "RenameSnapshot", @, label

  setCreatedAt: (createdAt) ->
    @createdAtView.updatePartial nicetime createdAt - Date.now()
    return

  setLabel: (label) ->
    @nameView.updatePartial label
    @editView.inputs.name.setValue label
    return

  setStorageSize: (storageSize) ->
    console.warn "SnapshotListItem.setStorageSize: Storage size not supported yet"
    return

  toggleEditable: ->
    if @infoView.$().is ":visible"
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editView.inputs.name.bound "setFocus"
    else
      @infoView.show()
      @editView.hide()



