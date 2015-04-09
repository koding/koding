kd = require 'kd'
_  = require 'lodash'
Item = require './item'

module.exports =

class Pane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'


  viewAppended: ->

    #@collection.each (model) =>
    @addSubView new Item null, @collection.first()
    @addSubView new Item null, @collection.models[1]
