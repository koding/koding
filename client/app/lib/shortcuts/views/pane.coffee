kd       = require 'kd'
_        = require 'lodash'
recorder = require 'record-shortcuts'
Item     = require './item'


selectHandler = (cb) ->

  recorder.start()

    .on 'end', (res) =>
      if res.length < 2 then return cb()

      fn = (collection, model) =>
        @emit 'Synced', model

      { shortcuts } = kd.singletons

      shortcuts
        .once 'change', fn
        .update @model.collection, @model.name,
          binding: [ res.join '+' ]

      cb res

    .on 'cancel', cb

  return


toggleHandler = (enabled) ->

  fn = (collection, model) =>
    @emit 'Synced', model

  { shortcuts } = kd.singletons

  shortcuts
    .once 'change', fn
    .update @model.collection, @model.name,
      options: enabled: enabled

  return


module.exports =

class Pane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection

    super _.omit options, 'collection'


  destroy: ->

    @getSubViews().forEach (item) =>
      item.off 'Selected', selectHandler
      item.off 'Toggled' , toggleHandler

    super


  viewAppended: ->

    i = 0

    @collection.each (model) =>
      if ++i > 5 then return
      item = @addSubView new Item null, model
      item.on 'Selected', selectHandler
      item.on 'Toggled' , toggleHandler
