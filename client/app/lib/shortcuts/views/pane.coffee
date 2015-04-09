kd = require 'kd'
_  = require 'lodash'
ShortcutsListItem = require './listitem'

module.exports =

class ShortcutsPane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'


  viewAppended: ->

    #@collection.each (model) =>
    @addSubView new ShortcutsListItem null, @collection.first()
    @addSubView new ShortcutsListItem null, @collection.models[1]
