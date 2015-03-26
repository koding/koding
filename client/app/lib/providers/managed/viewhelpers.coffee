
kd    = require 'kd'

addTo = (parent, views)->
  map = {}
  for own key, value of views
    _key  = (key.split '_').first
    value = [value]  unless Array.isArray value
    unless view[_key]?
      throw message: "No such view with key of #{_key}!"
    map[key] = view[_key] value...
    parent.addSubView map[key].__view or map[key]

  return map

globals = require 'globals'
kontrolUrl = if globals.config.environment in ['dev', 'sandbox'] \
             then "KONTROLURL=#{globals.config.newkontrol.url} " else ''

contents  =
  install : """bash
    $ curl -sO https://s3.amazonaws.com/koding-klient/install.sh
    $ #{kontrolUrl}bash ./install.sh
    # Enter your koding.com credentials when asked for
  """

module.exports   = view =
  message        : ({text, cssClass}) -> new kd.View
    partial      : text
    cssClass     : "message #{cssClass ? ''}"

  header         : (title) -> new kd.View
    partial      : title
    cssClass     : 'view-header'

  loader         : ({show, cssClass})-> new kd.LoaderView
    showLoader   : show
    cssClass     : cssClass ? ''
    size         :
      width      : 20
      height     : 20

  code           : (code) -> new kd.View
    partial      : (require 'app/util/applyMarkdown') "```#{code}```"
    cssClass     : 'has-markdown'
    tagName      : 'article'

  instructions   : (content) ->
    content      = contents[content] ? content
    container    = new kd.View
    addTo container,
      header     : 'Instructions'
      code       : content
    return container

  waiting        : (text) ->

    container    = new kd.View
      cssClass   : 'view-waiting'
    addTo container,
      loader     : show: yes
      message    : {text}
    return container

  list           : ({data, itemClass}) ->

    itemClass   ?= require './kiteitem'
    controller   = new kd.ListViewController { selection: yes, itemClass }
    controller.replaceAllItems data

    if data.length > 0
      controller.selectSingleItem controller.getListItems().first

    __view = controller.getListView()

    __view.addItemView (new itemClass
      selectable : no
      isHeader   : yes
    ), 0

    return { __view, controller }

  button         : (options = {})->
    unless options.iconOnly
      options.cssClass = kd.utils.curry 'solid medium', options.cssClass
    new kd.ButtonView options

  retry          : ({text, callback})->

    container    = new kd.View
      cssClass   : 'view-waiting'

    addTo container,
      message     : {text}
      button      :
        iconOnly  : yes
        cssClass  : 'retry inline'
        callback  : callback

    return container

  addTo           : addTo
