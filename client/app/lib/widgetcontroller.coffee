htmlencode = require 'htmlencode'
kookies = require 'kookies'
remote = require('./remote').getInstance()
kd = require 'kd'
KDController = kd.Controller
module.exports = class WidgetController extends KDController

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

    remote.api.JCustomPartials.some query, {}, (err, widgets) =>
      return  unless widgets or err
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
    isPreviewMode = kookies.get "custom-partials-preview-mode"
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
          kd.warn "#{key} widget failed to load"

  evalJS: (view, js) ->
    jsCode = "viewId = '#{view.getId()}'; #{js}"
    eval htmlencode.htmlDecode jsCode

  appendCSS: (css, key) ->
    domId         = "#{key}WidgetStyle"
    oldElement    = global.document.getElementById domId
    global.document.head.removeChild oldElement  if oldElement

    tag           = global.document.createElement "style"
    tag.id        = domId
    tag.innerHTML = htmlencode.htmlDecode css

    global.document.head.appendChild tag
