kd = require 'kd'
_ = require 'underscore'

module.exports = class ShortcutsList extends kd.View

  constructor: (options={}, keymap) ->

    keys = ['cmd', 'description', 'keys', 'enabled']
    super options, _.map keymap, (set) -> _.object keys, set

  viewAppended: ->

    list = new kd.CustomHTMLView
      tagName: 'ul'

    @data.forEach (item) ->
      view = new kd.CustomHTMLView
        tagName: 'li'
        partial: """
          <p>#{item.description}</p>
        """

      list.addSubView view

    @addSubView list
