kd = require 'kd'
_ = require 'lodash'
Item = require './item'

module.exports =

class Pane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'

  # XXX: add sub-views on PaneDidShow instead
  viewAppended: ->

    dups = kd.getSingleton('shortcuts').getCollisionsFlat @collection._key

    @collection.each (model) =>
      item = @addSubView new Item null, model, _.includes dups, model.name
