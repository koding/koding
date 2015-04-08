kd = require 'kd'
_  = require 'lodash'
ShortcutsListItem = require './listitem'

module.exports =

class ShortcutsPane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection

    super _.omit options, 'collection'


  viewAppended: ->

    listController = new kd.ListViewController
      view: new kd.ListView
        itemClass: ShortcutsListItem

    #@collection.each (model) ->
      #listController.addItem model

    listController.addItem @collection.first()

    @addSubView listController.getView()
