class HomePageCustomViewItem extends CustomViewItem

  creteElements: ->
    super

    @previewToggle  = new KodingSwitch
      cssClass      : "dark preview-toggle"
      defaultValue  : @getData().isPreview
      callback      : => @updateState "isPreview"

    @activateToggle = new KodingSwitch
      cssClass      : "dark publish"
      defaultValue  : @getData().isActive
      callback      : => @updateState "isActive"

    @previewToggle.addSubView new KDCustomHTMLView
      tagName       : "span"
      partial       : "Preview"

    @activateToggle.addSubView new KDCustomHTMLView
      tagName       : "span"
      partial       : "Publish"

  updateState: (key) ->
    delegate = @getDelegate()
    data     = @getData()

    for customView in delegate.customViews
      oldActive = customView  if customView.getData()[key] is yes

    toggleState = =>
      changeSet      = {}
      changeSet[key] = !data[key]

      data.update changeSet, (err, res) =>
        return warn err  if err
        delegate.reloadViews()

    if oldActive
      changeSet      = {}
      changeSet[key] = no

      oldActive.getData().update changeSet, (err, res) =>
        return warn err  if err
        toggleState()
    else
      toggleState()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      {{> @previewToggle}}
      {{> @activateToggle}}
      <div class="button-container">
        {{> @deleteButton}}
        {{> @editButton}}
      </div>
    """
