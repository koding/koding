kd = require 'kd'
_  = require 'lodash'
Item = require './item'
record = require '../record'

module.exports =

class Pane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'


  viewAppended: ->

    i = 0
    @collection.each (model) =>
      if ++i > 5 then return
      item = @addSubView new Item null, model
      item.on 'BindingSelected', (id) =>
        record (seq) ->
          console.log seq
