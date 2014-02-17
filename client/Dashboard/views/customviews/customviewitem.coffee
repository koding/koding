class CustomViewItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "custom-view-item"

    super options, data

    @creteElements()

  creteElements: ->
    @deleteButton = new KDButtonView
      cssClass    : "delete"
      iconOnly    : yes
      callback    : =>
        @notify => @delete()

    @editButton   = new KDButtonView
      cssClass    : "edit"
      iconOnly    : yes
      callback    : @bound "edit"

  notify: (callback = noop) ->
    modal          = new KDModalView
      title        : "Are you sure?"
      content      : "Are you sure you want to delete the item. This cannot be undone."
      overlay      : yes
      buttons      :
        Delete     :
          title    : "Delete"
          cssClass : "modal-clean-red"
          callback : =>
            callback()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

  edit: ->
    @getDelegate().emit "ViewEditRequested", @getData()

  delete: ->
    viewData = @getData()
    viewData.remove (err, res) =>
      return warn err  if err
      @getDelegate().emit "ViewDeleted", viewData
      @destroy()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      <div class="button-container">
        {{> @deleteButton}}
        {{> @editButton}}
      </div>
    """
