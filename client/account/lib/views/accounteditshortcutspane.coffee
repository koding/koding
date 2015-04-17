kd = require 'kd'
_ = require 'lodash'
Row = require './accounteditshortcutsrow'

module.exports =

class AccountEditShortcutsPane extends kd.View

  constructor: (options={}) ->

    @collection = options.collection
    super _.omit options, 'collection'

  # XXX: add sub-views on PaneDidShow instead
  viewAppended: ->

    dups = kd.getSingleton('shortcuts').getCollisionsFlat @collection._key

    @collection.each (model) =>
      dup = _.includes dups, model.name
      item = @addSubView new Row dup: dup, model
