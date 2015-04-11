kd       = require 'kd'
_        = require 'lodash'
recorder = require 'record-shortcuts'
Item     = require './item'


listeners = {}

selectHandler = (cb) ->

  recorder.start()
    .on 'end', (res) ->
      { shortcuts } = kd.singletons
      cb res
    .on 'cancel', cb


toggleHandler = (enabled) ->

  { shortcuts } = kd.singletons

  uid = [@model.collection, @model.name].join '|'
  fn = listeners[uid] = (collection, model) =>
    console.log arguments
    @emit 'Synced', model

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
