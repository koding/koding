kd                  = require 'kd'
_                   = require 'lodash'
Row                 = require './accounteditshortcutsrow'
KDCustomScrollView  = kd.CustomScrollView

module.exports =

class AccountEditShortcutsPane extends kd.TabPaneView

  constructor: (options = {}) ->

    @collection = options.collection
    super _.omit options, 'collection'

  # XXX: add sub-views on PaneDidShow instead
  viewAppended: ->

    scrollView = new KDCustomScrollView

    dups = kd.getSingleton('shortcuts').getCollisionsFlat @collection._key

    @collection.each (model) ->
      dup   = _.includes dups, model.name
      scrollView.wrapper.addSubView new Row { dup }, model

    @addSubView scrollView
