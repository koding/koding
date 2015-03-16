kd                = require 'kd'
ShortcutsListItem = require './list-item'
xtend             = require 'xtend'

module.exports =

class ShortcutsListController extends kd.ListViewController

  constructor: (options={}, data) ->

    options = xtend options,
      selection: true
      view: new kd.ListView
        cssClass: 'shortcuts-list'
        itemClass: ShortcutsListItem

    super options, data
