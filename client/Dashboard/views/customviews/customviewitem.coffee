class CustomViewItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "custom-view-item"

    super options, data

    @creteElements()

  creteElements: ->
    @deleteButton = new KDButtonView
      cssClass    : "delete"
      icon        : yes
      iconOnly    : yes
      callback    : @bound "delete"

    @editButton   = new KDButtonView
      cssClass    : "edit"
      icon        : yes
      iconOnly    : yes
      callback    : @bound "edit"

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
