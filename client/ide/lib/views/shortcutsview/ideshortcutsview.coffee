kd                 = require 'kd'
KDCustomHTMLView   = kd.CustomHTMLView
KDCustomScrollView = kd.CustomScrollView
IDEShortcutView    = require './ideshortcutview'

module.exports =

class IDEShortcutsView extends KDCustomScrollView

  constructor: (options = {}, data) ->

    super options, data

    @wrapper.setClass 'key-mappings'

    shortcuts = @getShortcuts()

    for title, mapping of shortcuts
      container = new KDCustomHTMLView
        cssClass: 'container clearfix'
        partial : "<p>#{title}</p>"

      for description, shortcut of mapping
        container.addSubView new IDEShortcutView {}, { shortcut, description }

      @wrapper.addSubView container


  getShortcuts: ->

    { shortcuts } = kd.singletons

    shortcuts.toJSON().reduce (sum, collection) ->
      key = "#{collection.title} Shortcuts"
      sum[key] =
        collection.data.reduce (acc, model) ->
          if model.binding.length
            acc[model.description] = model.binding[0].replace /\+/g, '-'
          return acc
        , {}
      return sum
    , {}
