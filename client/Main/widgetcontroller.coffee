class WidgetController extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @placeholders = {}
    @widgets      =
      preview     : {}
      published   : {}

    @registerPlaceholders()
    @fetchWidgets()

  fetchWidgets: ->
    query =
      partialType : "WIDGET"
      "$or"       : [
        { isActive: yes  }
        { isPreview: yes }
      ]

    KD.remote.api.JCustomPartials.some query, {}, (err, widgets) =>
      for widget in widgets
        target   = "published"
        key      = "viewInstance"

        if widget.isPreview
          target = "preview"
          key    = "previewInstance"

        @widgets[target][widget[key]] = widget

  registerPlaceholders: ->
    @placeholders.ActivityTop  = { title: "Activity Top",  key: "ActivityTop"  }
    @placeholders.ActivityLeft = { title: "Activity Left", key: "ActivityLeft" }

  getPlaceholders: ->
    return @placeholders

  showWidgets: (widgets) ->
    isPreviewMode = $.cookie "custom-partials-preview-mode"
    targetKey     = if isPreviewMode then "preview" else "published"

    for widget in widgets
      {view, key}    = widget
      widgetData     = @widgets[targetKey][key]
      hasPlaceholder = @placeholders[key]

      if view and key and widgetData and hasPlaceholder
        try
          {css, js}  = widgetData.partial
          @evalJS    view, js  if js
          @appendCSS css, key  if css
        catch
          warn "#{key} widget failed to load"

  evalJS: (view, js) ->
    view.addSubView eval Encoder.htmlDecode js

  appendCSS: (css, key) ->
    domId         = "#{key}WidgetStyle"
    oldElement    = document.getElementById domId
    document.head.removeChild oldElement  if oldElement

    tag           = document.createElement "style"
    tag.id        = domId
    tag.innerHTML = css

    document.head.appendChild tag
