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

    @activateToggle = new KodingSwitch
      cssClass      : "dark"
      defaultValue  : @getData().isActive
      callback      : @bound "updateState"

  updateState: ->
    delegate = @getDelegate()
    data     = @getData()

    for customView in delegate.customViews
      oldActive = customView  if customView.getData().isActive is yes

    toggleState = =>
      data.update { isActive: !data.isActive }, (err, res) =>
        return warn err  if err
        delegate.reloadViews()

    if oldActive
      oldActive.getData().update { isActive: no }, (err, res) =>
        return warn err  if err
        toggleState()
    else
      toggleState()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
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

    @assignSelect   = new KDSelectBox
      cssClass      : "assign solid green"
      selectOptions : selectOptions
      defaultValue  : @getData().viewInstance ? "NOT_VISIBLE"
      callback      : @bound "updateState"

  updateState: (value) ->
    delegate = @getDelegate()
    data     = @getData()

    for customView in delegate.customViews
      if customView.getData().viewInstance is value
        oldActive = customView

    toggleState = =>
      data.update { isActive: yes, viewInstance: value }, (err, res) =>
        return warn err  if err
        delegate.reloadViews()

    if oldActive
      oldActive.getData().update { isActive: no, viewInstance: "NOT_VISIBLE" }, (err, res) =>
        return warn err  if err
        toggleState()
    else
      toggleState()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      {{> @assignSelect}}
      <div class="button-container">
        {{> @deleteButton}}
        {{> @editButton}}
      </div>
    """
