
kd    = require 'kd'

addTo = (parent, views)->
  map = {}
  for own key, value of views
    value = [value]  unless Array.isArray value
    map[key] = view[key] value...
    parent.addSubView map[key].__view or map[key]

  return map

module.exports   = view =
  message        : (message) -> new kd.View
    partial      : message
    cssClass     : 'title'

  header         : (title) -> new kd.View
    partial      : title
    cssClass     : 'view-header'

  loader         : -> new kd.LoaderView
    showLoader   : yes
    size         :
      width      : 20
      height     : 20

  code           : (code) -> new kd.View
    partial      : (require 'app/util/applyMarkdown') "```#{code}```"
    cssClass     : 'has-markdown'
    tagName      : 'article'

  instructions   : (content) ->
    container    = new kd.View
    addTo container,
      header     : 'Instructions'
      code       : content
    return container

  waiting        : (text) ->
    container    = new kd.View
      cssClass   : 'view-waiting'
    addTo container,
      loader     : null
      message    : text
    return container

  list           : ({data, itemClass}) ->

    itemClass   ?= require './kiteitem'
    controller   = new kd.ListViewController { selection: yes, itemClass }
    controller.replaceAllItems data

    return { __view: controller.getView(), controller }

  button         : (options)->
    new kd.ButtonView options

  retry          : ({text, callback})->
    container    = new kd.View
      cssClass   : 'view-waiting'

    addTo container,
      message     : text
      button      :
        iconOnly  : yes
        cssClass  : 'retry'
        callback  : callback

    return container

  addTo           : addTo
