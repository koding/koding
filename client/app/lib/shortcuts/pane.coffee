kd = require 'kd'
_ = require 'lodash'
Item = require './item'

module.exports =

class Pane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'

  viewAppended: ->
    # XXX: add sub-views on PaneDidShow instead

    @collection.each (model) =>
      item = @addSubView new Item null, model
