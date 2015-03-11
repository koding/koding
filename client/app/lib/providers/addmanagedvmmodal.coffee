kd = require 'kd'
nick = require 'app/util/nick'
showError = require 'app/util/showError'
{generateQueryString} = require '../kite/kitecache'

States = {
  'Retry'
  'Initial'
  'ListKites'
  'FailedToConnect'
}

INSTALL_INSTRUCTIONS = """bash
  $ curl https://kd.io/kites/klient/latest | bash -
  # Enter your koding.com credentials when asked for
"""

class KiteItem extends kd.ListItemView
  partial: ( { kite } )->
    "#{kite.name} on #{kite.hostname} with #{kite.id} ID"


view             =

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


addTo = (parent, views)->

  map = {}
  for own key, value of views
    value = [value]  unless Array.isArray value
    map[key] = view[key] value...
    parent.addSubView map[key].__view or map[key]

  return map


getIp = (url)->
  _ = global.document.createElement 'a'
  _.href = url
  _.hostname


module.exports = class AddManagedVMModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options    =
      title    : 'Add your own VM'
      width    : 640
      cssClass : 'managed-vm modal'

    super options, data

    @addSubView @container = new kd.View


  viewAppended: -> @switchTo States.Initial


  switchTo: (state, data)->

    @container.destroySubViews()

    switch state

      when States.Initial

        addTo @container,
          instructions : INSTALL_INSTRUCTIONS
          waiting      : 'Checking for kite instances...'

        @queryKites()
          .then (result) =>
            if result?.kites?.length
            then @switchTo States.ListKites, result.kites
            else @switchTo States.Retry, 'No kite instance found'
          .catch (err) =>
            console.warn "Error:", err
            @switchTo States.Retry, 'Failed to query kites'

      when States.Retry

        addTo @container,
          instructions : INSTALL_INSTRUCTIONS
          retry        :
            text       : data
            callback   : @lazyBound 'switchTo', States.Initial

      when States.ListKites

        addTo @container,
          instructions : INSTALL_INSTRUCTIONS
          list         : data


  queryKites: ->

    kd.singletons.kontrol
      .queryKites
        query         :
          username    : nick()
          environment : 'managed'
      .timeout 5000
