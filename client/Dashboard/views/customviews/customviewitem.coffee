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

class WidgetCustomViewItem extends CustomViewItem

  creteElements: ->
    super

    selectOptions    = [ { title : "Not Active", value : "NOT_VISIBLE" } ]
    widgetController = KD.getSingleton "widgetController"

    for key, widget of widgetController.getPlaceholders()
      selectOptions.push { title: widget.title, value: widget.key }

    data = @getData()

    @assignSelect   = new KDSelectBox
      preview       : "Publish"
      cssClass      : "assign solid green"
      selectOptions : selectOptions
      defaultValue  : data.isActive and data.viewInstance ? "NOT_VISIBLE"
      callback      : (value) => @updateState value

    @previewSelect  = new KDSelectBox
      title         : "Preview"
      cssClass      : "solid green preview-select"
      selectOptions : selectOptions
      defaultValue  : data.isPreview and data.previewInstance ? "NOT_VISIBLE"
      callback      : (value) => @updateState value, yes

    @previewLabel   = new KDCustomHTMLView
      tagName       : "span"
      cssClass      : "select-label"
      partial       : "Preview"

    @assignLabel    = new KDCustomHTMLView
      tagName       : "span"
      cssClass      : "select-label assign"
      partial       : "Publish"

  updateState: (value, previewRequest) ->
    delegate = @getDelegate()
    data     = @getData()

    stateKey = "isActive"
    viewKey  = "viewInstance"

    if previewRequest
      stateKey = "isPreview"
      viewKey  = "previewInstance"

    for customView in delegate.customViews
      if customView.getData()[viewKey] is value
        oldActive = customView

    toggleState = =>
      changeSet = {}
      changeSet[stateKey] = yes
      changeSet[viewKey]  = value

      data.update changeSet, (err, res) =>
        return warn err  if err
        delegate.reloadViews()

    if oldActive
      changeSet = {}
      changeSet[viewKey]  = "NOT_VISIBLE"
      changeSet[stateKey] = no

      oldActive.getData().update changeSet, (err, res) =>
        return warn err  if err
        toggleState()
    else
      toggleState()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      {{> @previewSelect}}
      {{> @previewLabel}}
      {{> @assignSelect}}
      {{> @assignLabel}}
      <div class="button-container">
        {{> @deleteButton}}
        {{> @editButton}}
      </div>
    """
