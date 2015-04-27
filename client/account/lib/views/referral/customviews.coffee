kd = require 'kd'

module.exports = class CustomViews

  MIXINS = ['views', 'addTo', 'addCustomViews']
  @mixin = (target) ->
    target[mixin] = this[mixin] for mixin in MIXINS

  @views      =
    view      : (options, data) ->
      new kd.View options, data
    text      : (text, cssClass) =>
      @views.view partial: text, cssClass: "text #{cssClass ? ''}"
    container : (options, cssClass) =>

      if typeof options is 'string'
        return @views.view cssClass: options

      container = @views.view {cssClass}
      @addTo container, options
      return container

    link      : (options) ->
      new (require 'app/customlinkview') options

  @addTo   = (parent, views)->

    map    = {}
    length = 0

    for own key, value of views
      [_key, _customKey] = key.split '_'
      value = [value]  unless Array.isArray value

      unless @views[_key]?
        value = ["No such view with key of '#{_key}'!"]
        console.warn value.first
        _key  = 'text'

      value.push _customKey  if _customKey?

      map[key] = @views[_key] value...
      parent.addSubView map[key].__view or map[key]
      length++

    return map[key]  if length is 1
    return map

  @addCustomViews = (views)->
    @addTo this, views
