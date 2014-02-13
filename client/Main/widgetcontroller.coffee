class WidgetController extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @widgets      = {}
    @placeholders = {}

    @registerPlaceholders()
    @fetchWidgets()

  fetchWidgets: ->
    query = { isActive: yes, partialType: "WIDGET" }

    KD.remote.api.JCustomPartials.some query, {}, (err, widgets) =>
      @widgets[widget.viewInstance] = widget  for widget in widgets

  registerPlaceholders: ->
    @placeholders.ActivityTop  = { title: "Activity Top",  key: "ActivityTop"  }
    @placeholders.ActivityLeft = { title: "Activity Left", key: "ActivityLeft" }

  getPlaceholders: ->
    return @placeholders

  showWidgets: (widgets) ->
    for widget in widgets
      {view, key}    = widget
      widgetData     = @widgets[key]
      hasPlaceholder = @placeholders[key]

      if view and key and widgetData and hasPlaceholder
        try
          view.addSubView eval Encoder.htmlDecode widgetData.partial
        catch
          warn "#{key} widget failed to load"
