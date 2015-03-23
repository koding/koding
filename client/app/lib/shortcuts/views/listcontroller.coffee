kd                = require 'kd'
ShortcutsListItem = require './listitem'
_                 = require 'underscore'

module.exports =

class ShortcutsListController extends kd.ListViewController

  constructor: (options={}, data) ->

    options = _.extend {}, options,
      view        : new kd.ListView
        cssClass  : 'shortcuts-list'
        itemClass : ShortcutsListItem

    super options, data
