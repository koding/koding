kd = require 'kd'
ShortcutsListItem = require './list-item'

module.exports =

class ShortcutsListController extends kd.ListViewController

  constructor: (options={}, collection) ->

    options.useCustomScrollView = no
    options.viewOptions =
      itemClass: ShortcutsListItem

    super options, collection

    collection.each (model) =>
      @addItem
        name: model.description
